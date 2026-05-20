The overflowing RenderFlex has an orientation of Axis.vertical.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#e57c3 relayoutBoundary=up3 OVERFLOWING:
  needs compositing
  creator: Column ← Padding ← LayoutBuilder ← KeyedSubtree-[GlobalKey#b23d2] ← _BodyBuilder ←
    MediaQuery ← LayoutId-[<_ScaffoldSlot.body>] ← CustomMultiChildLayout ← _ActionsScope ← Actions ←
    AnimatedBuilder ← DefaultTextStyle ← ⋯
  parentData: offset=Offset(20.0, 20.0) (can use size)
  constraints: BoxConstraints(0.0<=w<=352.7, 0.0<=h<=647.8)
  size: Size(352.7, 647.8)
  direction: vertical
  mainAxisAlignment: start
  mainAxisSize: max
  crossAxisAlignment: stretch
  verticalDirection: down
  spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════