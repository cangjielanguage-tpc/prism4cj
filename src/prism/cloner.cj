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
        let hash: Int64 = grammar.hashCode()
        if (let Some(v) <- context.grammar(hash)) {
            return v
        }
        let tokens: ArrayList<Token> = grammar.tokens()
        let out: ArrayList<Token> = ArrayList<Token>(tokens.size)
        let contextGrammar = GrammarImpl(grammar.name(), out)
        context.save(hash, contextGrammar)
        for (i in 0..tokens.size) {
            out.add(clone(context, tokens[i]))
        }
        return contextGrammar
    }

    func clone(context: Context, token: Token): Token {
        let hash: Int64 = token.hashCode()
        if (let Some(v) <- context.token(hash)) {
            return v
        }
        let patterns: ArrayList<Pattern> = token.patterns()
        let out: ArrayList<Pattern> = ArrayList<Pattern>(patterns.size)
        let contextToken = TokenImpl(token.name(), out)
        context.save(hash, contextToken)
        for (i in 0..patterns.size) {
            out.add(clone(context, patterns[i]))
        }
        return contextToken
    }

    func clone(context: Context, pattern: Pattern): Pattern {
        let hash: Int64 = pattern.hashCode()
        if (let Some(v) <- context.pattern(hash)) {
            return v
        }
        let inside: ?Grammar = pattern.inside()
        let contextPattern: Pattern
        if (let Some(v) <- inside) {
            contextPattern = PatternImpl(pattern.regex(), pattern.lookbehind(), pattern.greedy(), pattern.alias(),
                clone(context, v))
        } else {
            contextPattern = PatternImpl(pattern.regex(), pattern.lookbehind(), pattern.greedy(), pattern.alias(), None)
        }
        context.save(hash, contextPattern)
        return contextPattern
    }
}

interface Context {
    func grammar(hash: Int64): ?Grammar

    func token(hash: Int64): ?Token

    func pattern(hash: Int64): ?Pattern

    func save(hash: Int64, clone: Grammar): Unit

    func save(hash: Int64, clone: Token): Unit

    func save(hash: Int64, clone: Pattern): Unit
}

class ContextImpl <: Context {
    private let cache: HashMap<Int64, Any> = HashMap<Int64, Any>(3)

    public func grammar(hash: Int64): ?Grammar {
        return match (cache.get(hash)) {
            case Some(v) => v as Grammar
            case None => None
        }
    }

    public func token(hash: Int64): ?Token {
        return match (cache.get(hash)) {
            case Some(v) => v as Token
            case None => None
        }
    }

    public func pattern(hash: Int64): ?Pattern {
        return match (cache.get(hash)) {
            case Some(v) => v as Pattern
            case None => None
        }
    }

    public func save(hash: Int64, clone: Grammar): Unit {
        cache.add(hash, clone)
    }

    public func save(hash: Int64, clone: Token): Unit {
        cache.add(hash, clone)
    }

    public func save(hash: Int64, clone: Pattern): Unit {
        cache.add(hash, clone)
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
