package prism4cj.prism

internal import std.collection.ArrayList
internal import std.collection.HashMap
internal import std.collection.HashSet
internal import std.regex.Matcher
internal import std.regex.Regex
internal import std.regex.RegexException
internal import std.regex.MatchData

public class Prism {
    var grammarLocator: GrammarLocator

    public init(grammarLocator: GrammarLocator) {
        this.grammarLocator = grammarLocator
    }

    public func grammar(name: String): ?Grammar {
        return grammarLocator.grammar(this, name)
    }

    public static func token(name: String, patterns: ArrayList<Pattern>): Token {
        return TokenImpl(name, patterns)
    }

    public static func token(name: String, patterns: Array<Pattern>): Token {
        return TokenImpl(name, ArrayList(patterns))
    }

    public static func pattern(regex: Regex): Pattern {
        return PatternImpl(regex, false, false, None, None)
    }

    public static func pattern(regex: Regex, lookbehind: Bool): Pattern {
        return PatternImpl(regex, lookbehind, false, None, None)
    }

    public static func pattern(regex: Regex, lookbehind: Bool, greedy: Bool): Pattern {
        return PatternImpl(regex, lookbehind, greedy, None, None)
    }

    public static func pattern(regex: Regex, lookbehind: Bool, greedy: Bool, alias: ?String): Pattern {
        return PatternImpl(regex, lookbehind, greedy, alias, None)
    }

    public static func pattern(regex: Regex, lookbehind: Bool, greedy: Bool, alias: ?String, inside: ?Grammar): Pattern {
        return PatternImpl(regex, lookbehind, greedy, alias, inside)
    }

    public func tokenize(text: String, grammar: Grammar): ArrayList<Node> {
        var entries: ArrayList<Node> = ArrayList<Node>(3)
        entries.add(TextImpl(text))
        matchGrammar(text, entries, grammar, 0, 0, false, None)
        return entries
    }

    private func matchGrammar(
        text: String,
        entries: ArrayList<Node>,
        grammar: Grammar,
        index: Int64,
        startPosition: Int64,
        oneShot: Bool,
        target: ?Token
    ): Unit {
        let textLength: Int64 = text.size
        for (token in grammar.tokens()) {
            if (let Some(v) <- target) {
                if (token == v) {
                    return
                }
            }
            for (pattern in token.patterns()) {
                let lookbehind: Bool = pattern.lookbehind()
                let greedy: Bool = pattern.greedy()
                var lookbehindLength: Int64 = 0
                let regex: Regex = pattern.regex()
                let patternInside: ?Grammar = pattern.inside()
                // Don't cache textLength as it changes during the loop
                var i: Int64 = index
                var position: Int64 = startPosition
                while (i < entries.size) {
                    if (entries.size > textLength) {
                        throw Exception(
                            "prism internal error. Number of entry nodes " + "is greater that the text length.\n" +
                            "Nodes: " + entries.toString() + "\n" + "Text: " + text)
                    }
                    let node: Node = entries[i]
                    if (isSyntaxNode(node)) {
                        position += node.textLength()
                        i++
                        continue
                    }
                    let textNode: Text = match (node as Text) {
                        case Some(v) => v
                        case None => break
                    }
                    var str: String = textNode.literal()
                    var deleteCount: Int64
                    var greedyMatch: Bool
                    var greedyAdd: Int64 = 0
                    var matchData: ?MatchData = None
                    if (greedy && i != entries.size - 1) {
                        let matcher: Matcher = regex.matcher(text)
                        // limit search to the position (?)
                        matcher.setRegion(position, textLength)
                        matchData = matcher.find()
                        if (matchData.isNone()) {
                            break
                        }
                        let matchRealData: MatchData = match (matchData) {
                            case Some(v) => v
                            case None => break
                        }
                        var begin: Int64 = matchRealData.matchPosition().start
                        if (lookbehind) {
                            try {
                                begin += matchRealData.matchString(1).size
                            } catch (e: Exception) {
                                break
                            }
                        }
                        var to: Int64 = 0
                        try {
                            to = matchRealData.matchPosition().start + matchRealData.matchString(0).size
                        } catch (e: Exception) {
                            break
                        }
                        var k = i
                        var p = position
                        let len: Int64 = entries.size
                        while (k < len) {
                            let current: Node = entries[k]
                            if (!(p < to || (!isSyntaxNode(current) &&
                                !isGreedyNode(entries[k - 1])))) {
                                break
                            }
                            p += current.textLength()
                            // Move the index i to the element in strarr that is closest to from
                            if (begin >= p) {
                                i += 1
                                position = p
                            }
                            k++
                        }
                        if (i < entries.size && isSyntaxNode(entries[i])) {
                            position += entries[i].textLength()
                            i++
                            continue
                        }
                        greedyMatch = true
                        deleteCount = k - i
                        greedyAdd = -position
                        str = text[position..p]
                    } else {
                        greedyMatch = false
                        deleteCount = 1
                    }
                    if (!greedyMatch) {
                        matchData = regex.find(str, group: lookbehind)
                        if (matchData.isNone()) {
                            if (oneShot) {
                                break
                            }
                            position += node.textLength()
                            i++
                            continue
                        }
                    }
                    let matchRealData2: MatchData = match (matchData) {
                        case Some(v) => v
                        case None => break
                    }
                    if (lookbehind) {
                        var group: String = ""
                        try {
                            group = matchRealData2.matchString(1)
                        } catch (e: Exception) {}
                        lookbehindLength = group.size
                    }
                    let begin02: Int64 = matchRealData2.matchPosition().start + greedyAdd + lookbehindLength
                    var mat: String
                    if (lookbehindLength > 0) {
                        try {
                            mat = matchRealData2.matchString()[lookbehindLength..]
                        } catch (e: Exception) {
                            break
                        }
                    } else {
                        try {
                            mat = matchRealData2.matchString()
                        } catch (e: Exception) {
                            break
                        }
                    }
                    var to02: Int64 = begin02 + mat.size
                    for (_ in 0..deleteCount) {
                        entries.remove(at: i)
                    }
                    var i2: Int64 = i
                    if (begin02 != 0) {
                        var before: String = ""
                        try {
                            before = str[..begin02]
                        } catch (e: Exception) {
                            break
                        }
                        i += 1
                        position += before.size
                        entries.add(TextImpl(before), at: i2)
                        i2++
                    }
                    let hasInside: Bool = patternInside.isSome()
                    var tokenEntries: ArrayList<Node>
                    if (hasInside) {
                        tokenEntries = tokenize(mat, match (patternInside) {
                            case Some(v) => v
                            case None => break
                        })
                    } else {
                        tokenEntries = ArrayList<Node>(1)
                        tokenEntries.add(TextImpl(mat))
                    }
                    let syntaxImp: Syntax = SyntaxImpl(token.name(), tokenEntries, pattern.alias(), mat, greedy,
                        hasInside)
                    entries.add(syntaxImp, at: i2)
                    i2++
                    // important thing here (famous off-by one error) to check against full length (not `length - 1`)
                    if (to02 < str.size) {
                        var after: String = ""
                        try {
                            after = str[to02..]
                        } catch (e: Exception) {
                            break
                        }
                        entries.add(TextImpl(after), at: i2)
                    }
                    if (deleteCount != 1) {
                        matchGrammar(text, entries, grammar, i, position, true, token)
                    }
                    if (oneShot) {
                        break
                    }
                    match (entries.get(i)) {
                        case Some(v) => position += v.textLength()
                        case None => ()
                    }
                    i++
                }
            }
        }
    }

    private static func isSyntaxNode(node: Node): Bool {
        return node.isSyntax()
    }

    private static func isGreedyNode(node: Node): Bool {
        if (!node.isSyntax()) {
            return false
        }
        return match (node as Syntax) {
            case Some(v) => v.greedy()
            case None => false
        }
    }
}
