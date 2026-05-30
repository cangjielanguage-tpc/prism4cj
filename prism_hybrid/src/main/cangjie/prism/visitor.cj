/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

package prism4cj.prism

/**
 * @see AbsVisitor
 */
public interface Visitor {
    func visit(nodes: ArrayList<Node>): Unit
}

public abstract class AbsVisitor <: Visitor {
    public open override func visit(nodes: ArrayList<Node>): Unit {
        for (i in 0..nodes.size) {
            if (nodes[i].isSyntax()) {
                match (nodes[i] as Syntax) {
                    case Some(syntaxNode) => visitSyntax(syntaxNode)
                    case None => throw Exception("Unexpected: isSyntax()=true but cast failed for node at index " + i.toString())
                }
            } else {
                match (nodes[i] as Text) {
                    case Some(textNode) => visitText(textNode)
                    case None => throw Exception("Unexpected: isText()=true but cast failed for node at index " + i.toString())
                }
            }
        }
    }

    protected func visitText(text: Text): Unit

    // do not forget to call visit(syntax.children()) inside
    protected func visitSyntax(x: Syntax): Unit
}
