import 'package:fastboard_flutter/src/widgets/flutter_after_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:whiteboard_sdk_flutter/whiteboard_sdk_flutter.dart';

import 'controller.dart';
import 'types/types.dart';
import 'widgets/default_builder.dart';
import 'widgets/widgets.dart';

/// Optional callback invoked when a fast room created. [controller] is
/// the [FastRoomController] for the created fast room view.
typedef FastRoomCreatedCallback = void Function(FastRoomController controller);

/// builder to customize controller widgets
typedef RoomControllerWidgetBuilder = Widget Function(
  BuildContext context,
  FastRoomController controller,
);

/// fast room view widget showing whiteboard
class FastRoomView extends StatefulWidget {
  /// Creates a new room view.
  /// The room view can be controlled using a `FastRoomController` that is passed to the
  /// `onFastRoomCreated` callback once the room is created.
  const FastRoomView({
    Key? key,
    required this.fastRoomOptions,
    this.theme,
    this.darkTheme,
    this.useDarkTheme = false,
    this.locate,
    this.onFastRoomCreated,
    this.builder = defaultControllerBuilder,
  }) : super(key: key);

  /// light theme data
  final FastThemeData? theme;

  /// dark theme data
  final FastThemeData? darkTheme;

  /// The locale to use for the fastboard, defaults to system locale
  /// supported :
  ///   Locale("en")
  ///   Locale("zh", "CN")
  final Locale? locate;

  /// dark mode config, true for darkTheme, false for lightTheme
  final bool useDarkTheme;

  /// fast room config info
  final FastRoomOptions fastRoomOptions;

  /// room created callback
  final FastRoomCreatedCallback? onFastRoomCreated;

  /// custom widgets see [defaultControllerBuilder]
  final RoomControllerWidgetBuilder builder;

  @override
  State<StatefulWidget> createState() {
    return FastRoomViewState();
  }
}

class FastRoomViewState extends State<FastRoomView> {
  late FastRoomController controller;

  @override
  void initState() {
    super.initState();
    controller = FastRoomController(widget.fastRoomOptions);
  }

  @override
  Widget build(BuildContext context) {
    FastGap.init(context);
    var themeData = _obtainThemeData();
    var whiteOptions = widget.fastRoomOptions.genWhiteOptions(
      backgroundColor: themeData.backgroundColor,
    );
    controller.updateThemeData(widget.useDarkTheme, themeData);
    return I18n(
      child: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: AfterLayout(
            callback: (renderAfterLayout) {
              debugPrint("room view changed: ${renderAfterLayout.size}");
              controller.updateRoomLayoutSize(renderAfterLayout.size);
            },
            child: Stack(
              children: [
                WhiteboardView(
                  options: whiteOptions,
                  onSdkCreated: (sdk) async {
                    await controller.joinRoomWithSdk(sdk);
                    widget.onFastRoomCreated?.call(controller);
                  },
                  useBasicWebView: true,
                ),
                FastTheme(
                    data: themeData,
                    child: Builder(builder: (context) {
                      return widget.builder(context, controller);
                    }))
              ],
            ),
          )),
      initialLocale: widget.locate,
    );
  }

  FastThemeData _obtainThemeData() {
    return widget.useDarkTheme
        ? widget.darkTheme ?? FastThemeData.dark()
        : widget.theme ?? FastThemeData.light();
  }

  @override
  void didUpdateWidget(FastRoomView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateWhiteIfNeed(oldWidget);
  }

  void _updateWhiteIfNeed(FastRoomView oldWidget) {
    if (oldWidget.useDarkTheme != widget.useDarkTheme) {
      controller.updateThemeData(widget.useDarkTheme, _obtainThemeData());
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
