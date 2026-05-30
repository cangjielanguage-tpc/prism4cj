/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package prism4cj.prism

abstract class Cloner {
    protected func clone(grammar: Grammar): Grammar

    protected func clone(grammar: Token): Token

    protected func clone(grammar: Pattern): Pattern

    static func create(): Cloner {
        return ClonerImpl()
    }
}

class ClonerImpl <: Cloner {
    protected func clone(grammar: Grammar): Grammar {
        return clone(ContextImpl(), grammar)
    }

    protected func clone(token: Token): Token {
        return clone(ContextImpl(), token)
    }

    protected func clone(pattern: Pattern): Pattern {
        return clone(ContextImpl(), pattern)
    }

    func clone(context: Context, grammar: Grammar): Grammar {
        var contextGrammar: ?Grammar = context.grammar(grammar)
        if (let Some(v) <- contextGrammar) {
            return v
        }
        let tokens: ArrayList<Token> = grammar.tokens()
        let out: ArrayList<Token> = ArrayList<Token>(tokens.size)
        let newGrammar: Grammar = GrammarImpl(grammar.name(), out)
        context.save(MyHashKey<Grammar>(grammar), newGrammar)
        for (i in 0..tokens.size) {
            out.add(clone(context, tokens[i]))
        }
        return newGrammar
    }

    func clone(context: Context, token: Token): Token {
        var contextToken: ?Token = context.token(token)
        if (let Some(v) <- contextToken) {
            return v
        }
        let patterns: ArrayList<Pattern> = token.patterns()
        let out: ArrayList<Pattern> = ArrayList<Pattern>(patterns.size)
        let newToken: Token = TokenImpl(token.name(), out)
        context.save(MyHashKey<Token>(token), newToken)
        for (i in 0..patterns.size) {
            out.add(clone(context, patterns[i]))
        }
        return newToken
    }

    func clone(context: Context, pattern: Pattern): Pattern {
        var contextPattern: ?Pattern = context.pattern(pattern)
        if (let Some(v) <- contextPattern) {
            return v
        }
        let inside: ?Grammar = pattern.inside()
        let newPattern: Pattern = match (inside) {
            case Some(g) => PatternImpl(pattern.regex(), pattern.lookbehind(), pattern.greedy(), pattern.alias(), clone(context, g))
            case None => PatternImpl(pattern.regex(), pattern.lookbehind(), pattern.greedy(), pattern.alias(), None)
        }
        context.save(MyHashKey<Pattern>(pattern), newPattern)
        return newPattern
    }
}

interface Context {
    func grammar(origin: Grammar): ?Grammar

    func token(origin: Token): ?Token

    func pattern(origin: Pattern): ?Pattern

    func save(origin: MyHashKey<Grammar>, clone: Grammar): Unit

    func save(origin: MyHashKey<Token>, clone: Token): Unit

    func save(origin: MyHashKey<Pattern>, clone: Pattern): Unit
}

class ContextImpl <: Context {
    private let cache: HashMap<Int64, Any> = HashMap<Int64, Any>(3)

    public func grammar(origin: Grammar): ?Grammar {
        return match (cache.get(origin.hashCode())) {
            case Some(v) => v as Grammar
            case None => None
        }
    }

    public func token(origin: Token): ?Token {
        return match (cache.get(origin.hashCode())) {
            case Some(v) => v as Token
            case None => None
        }
    }

    public func pattern(origin: Pattern): ?Pattern {
        return match (cache.get(origin.hashCode())) {
            case Some(v) => v as Pattern
            case None => None
        }
    }

    public func save(origin: MyHashKey<Grammar>, clone: Grammar): Unit {
        cache.add(origin.hashCode(), clone)
    }

    public func save(origin: MyHashKey<Token>, clone: Token): Unit {
        cache.add(origin.hashCode(), clone)
    }

    public func save(origin: MyHashKey<Pattern>, clone: Pattern): Unit {
        cache.add(origin.hashCode(), clone)
    }
}

public class MyHashKey<T> <: Hashable & Equatable<MyHashKey<T>> where T <: Hashable & Equatable<T> {
    let realKey: T
    public init(realKey: T) {
        this.realKey = realKey
    }
    public func hashCode(): Int64 {
        realKey.hashCode()
    }
    public operator func ==(a: MyHashKey<T>): Bool {
        return realKey == a.realKey
    }
    public operator func !=(a: MyHashKey<T>): Bool {
        return realKey != a.realKey
    }
}
