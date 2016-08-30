//
//  ResultMonad.swift
//  Psiphon-Browser
//
//  Created by Miro Kuratczyk on 2016-08-24.
//  Copyright © 2016 Psiphon. All rights reserved.
//

import Foundation

infix operator >>- { associativity left } // Monad's bind
infix operator <^>{ associativity left } // Functor's fmap (usually <$>)
infix operator <*> { associativity left } // Applicative's apply

/**
 infix bind operator
 */
func >>- <U,T> (
    left: Result<U>,
    right: (U) -> Result<T>) -> Result<T>
{
    return left.flatMap(f: right)
}

/**
 infix fmap operator
 */
func <^> <U,T> (
    left: (U) -> (T),
    right: Result<U>
    ) -> Result<T>
{
    return right.map(f: left)
}

/**
 infix applicative apply
 */
func <*> <U, T> (
    left: Result<(U)->(T)>,
    right: Result<U>
    ) -> Result<T>
{
    return right.ap(f: left)
}

/**
 Result monad
 */
enum Result<T> {
    case Value(T)
    case Error(String)
}

extension Result {
    // Inject a value into the monadic type
    func pure/*return*/<U>(a: (U)) -> Result<U> {
        return Result<U>.Value(a)
    }
    
    func map<U>(f: (T) -> U) -> Result<U> {
        switch self {
        case let .Value(value):
            return Result<U>.Value(f(value))
        case let .Error(error):
            return Result<U>.Error(error)
        }
    }
    
    func flatMap<U>(f: (T) -> Result<U>) -> Result<U> {
        return Result.flatten(result: map(f: f))
    }
    
    func ap<U>(f: Result<(T)->(U)>) -> Result<U> {
        switch self {
        case let .Value(x):
            switch f {
            case let .Value(fx):
                return Result<U>.Value(fx(x))
            case let .Error(error):
                return Result<U>.Error(error)
            }
        case let .Error(error):
            return Result<U>.Error(error)
        }
    }
    
    static func flatten<T>(result: Result<Result<T>>) -> Result<T> {
        switch result {
        case let .Value(innerResult):
            return innerResult
        case let .Error(error):
            return Result<T>.Error(error)
        }
    }
}
