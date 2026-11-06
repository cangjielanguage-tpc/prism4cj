import { codeStringToColorString, PrismBlock, PrismNode, PrismRes } from '@cangjie-tpc/prism_hybrid';

@Entry
@Component
struct Index24 {
  @State message: string = '1. 一级\n' +
    '   1. 二级\n' +
    '      1. 三级\n' +
    '         1. 四级\n' +
    '            1. 五级\n' +
    '               1. 六级';
  @State
  list: Array<PrismBlock> = new Array<PrismBlock>()
  @State
  txtBackground: number = undefined!
  @State
  defaultFontColor: number = undefined!

  async aboutToAppear(): Promise<void> {
    let prismRes: PrismRes = await codeStringToColorString(this.message, "markdown", true)
    this.txtBackground = prismRes.getBackground()
    this.defaultFontColor = prismRes.getDefaultFontColor()
    this.list = Array.from(prismRes.getListColor())
  }

  isColor(getColor: number | undefined): number {
    if (getColor == undefined) {
      return this.defaultFontColor
    } else {
      return getColor
    }
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Scroll() {
            Column() {
              List() {
                ForEach(this.list, (prismBlock: PrismBlock, index: number) => {
                  ListItem() {
                    Column() {
                      // Text(prismBlock.getText())
                      Text() {
                        ForEach(Array.from(prismBlock.getList()), (prismNode: PrismNode, index: number) => {
                          Span(prismNode.text)
                            .fontColor(this.isColor(prismNode.color))
                        })
                      }
                      .fontSize(14)
                      .textAlign(TextAlign.Start)
                    }
                  }
                })
              }
            }
            .justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.Start)
            .padding(10)
          }
          .backgroundColor(this.txtBackground)
          .scrollBar(BarState.Off)
          .scrollable(ScrollDirection.Horizontal)
          .width(`100%`)
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
      }
      .width(`100%`)
      .scrollable(ScrollDirection.Vertical)
      .padding({
        left: 10,
        right: 10,
        top: 20,
        bottom: 20
      })
    }
    .width(`100%`)
    .height(`100%`)
    .backgroundColor(Color.White)
  }
}
