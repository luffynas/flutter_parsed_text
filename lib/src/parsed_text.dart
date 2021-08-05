part of flutter_parsed_text;

enum TrimMode {
  Length,
  Line,
}

class ParsedText extends StatefulWidget {
  /// If non-null, the style to use for the global text.
  ///
  /// It takes a [TextStyle] object as it's property to style all the non links text objects.
  final TextStyle? style;

  /// Takes a list of [MatchText] object.
  ///
  /// This list is used to find patterns in the String and assign onTap [Function] when its
  /// tapped and also to provide custom styling to the linkify text
  final List<MatchText> parse;

  /// Text that is rendered
  ///
  /// Takes a [String]
  final String text;

  /// A text alignment property used to align the the text enclosed
  ///
  /// Uses a [TextAlign] object and default value is [TextAlign.start]
  final TextAlign alignment;

  /// A text alignment property used to align the the text enclosed
  ///
  /// Uses a [TextDirection] object and default value is [TextDirection.start]
  final TextDirection? textDirection;

  /// Whether the text should break at soft line breaks.
  ///
  ///If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  final int? maxLines;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.widgets.text.DefaultTextStyle.textWidthBasis}
  final TextWidthBasis textWidthBasis;

  /// Make this text selectable.
  ///
  /// SelectableText does not support softwrap, overflow, textScaleFactor
  final bool selectable;

  /// onTap function for the whole widget
  final Function? onTap;

  /// Global regex options for the whole string,
  ///
  /// Note: Removed support for regexOptions for MatchText and now it uses global regex options.
  final RegexOptions regexOptions;

  /// Creates a parsedText widget
  ///
  /// [text] paramtere should not be null and is always required.
  /// If the [style] argument is null, the text will use the style from the
  /// closest enclosing [DefaultTextStyle].
  ///
  final int trimLength;
  final int trimLines;
  final TrimMode trimMode;
  final TextStyle moreStyle;
  final TextStyle lessStyle;
  final Function(bool val)? callback;
  final String delimiter;
  final String trimExpandedText;
  final String trimCollapsedText;
  final Color? colorClickableText;
  final TextAlign? textAlign;
  final Locale? locale;
  final String? semanticsLabel;
  final TextStyle? delimiterStyle;
  final bool isLoadMore;

  const ParsedText({
    Key? key,
    this.trimExpandedText = 'Show less',
    this.trimCollapsedText = 'Show more',
    this.colorClickableText,
    this.trimLength = 240,
    this.trimLines = 2,
    this.trimMode = TrimMode.Line,
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.textScaleFactor = 1.0,
    this.semanticsLabel,
    this.moreStyle = const TextStyle(color: Colors.blue),
    this.lessStyle = const TextStyle(color: Colors.red),
    this.delimiter = _kEllipsis + ' ',
    this.delimiterStyle,
    this.callback,
    this.regexOptions = const RegexOptions(),
    this.parse = const <MatchText>[],
    this.alignment = TextAlign.start,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.maxLines,
    this.onTap,
    this.selectable = false,
    this.isLoadMore = true,
    required this.text,
  }) : super(key: key);

  @override
  ParsedTextState createState() => ParsedTextState();
}

const String _kEllipsis = '\u2026';

const String _kLineSeparator = '\u2028';

/// Parse text and make them into multiple Flutter Text widgets
class ParsedTextState extends State<ParsedText> {
  bool _readMore = true;

  void _onTapLink() {
    setState(() {
      _readMore = !_readMore;
    });
  }

  @override
  Widget build(BuildContext context) {
    String newString = widget.text;

    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle? effectiveTextStyle = widget.style;
    if (widget.style?.inherit ?? false) {
      effectiveTextStyle = defaultTextStyle.style.merge(widget.style);
    }

    final textAlign =
        widget.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start;
    final textDirection = widget.textDirection ?? Directionality.of(context);
    final textScaleFactor = widget.textScaleFactor;
    final overflow = defaultTextStyle.overflow;
    final locale = widget.locale ?? Localizations.maybeLocaleOf(context);
    final _defaultDelimiterStyle = widget.delimiterStyle ?? effectiveTextStyle;

    TextSpan _delimiter = TextSpan(
      text: _readMore
          ? widget.trimCollapsedText.isNotEmpty
              ? widget.delimiter
              : ''
          : '',
      style: _defaultDelimiterStyle,
      recognizer: TapGestureRecognizer()..onTap = _onTapLink,
    );

    Widget result = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      assert(constraints.hasBoundedWidth);
      bool isShowReadMore = true;

      final double maxWidth = constraints.maxWidth;

      // Create a TextSpan with data
      final text = TextSpan(
        style: effectiveTextStyle,
        text: widget.text,
      );

      // Layout and measure link
      TextPainter textPainter = TextPainter(
        text: _delimiter,
        textAlign: textAlign,
        textDirection: textDirection,
        textScaleFactor: textScaleFactor,
        maxLines: widget.trimLines,
        ellipsis: overflow == TextOverflow.ellipsis ? widget.delimiter : null,
        locale: locale,
      );
      textPainter.layout(minWidth: 0, maxWidth: maxWidth);
      final linkSize = textPainter.size;

      textPainter.layout(minWidth: 0, maxWidth: maxWidth);
      final delimiterSize = textPainter.size;

      // Layout and measure text
      textPainter.text = text;
      textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
      final textSize = textPainter.size;

      // Get the endIndex of data
      bool linkLongerThanLine = false;
      int endIndex;
      if (linkSize.width < maxWidth) {
        final readMoreSize = linkSize.width + delimiterSize.width;
        final pos = textPainter.getPositionForOffset(Offset(
          textDirection == TextDirection.rtl
              ? readMoreSize
              : textSize.width - readMoreSize,
          textSize.height,
        ));
        endIndex = textPainter.getOffsetBefore(pos.offset) ?? 0;
      } else {
        var pos = textPainter.getPositionForOffset(
          textSize.bottomLeft(Offset.zero),
        );
        endIndex = pos.offset;
        linkLongerThanLine = true;
      }

      switch (widget.trimMode) {
        case TrimMode.Length:
          if (widget.trimLength < widget.text.length) {
            newString = _readMore
                ? widget.text.substring(0, endIndex) +
                    (linkLongerThanLine ? _kLineSeparator : '...')
                : widget.text;
          } else {
            isShowReadMore = false;

            newString = widget.text;
          }
          break;
        case TrimMode.Line:
          if (textPainter.didExceedMaxLines) {
            newString = _readMore
                ? widget.text.substring(0, endIndex) +
                    (linkLongerThanLine ? _kLineSeparator : '...')
                : widget.text;
          } else {
            isShowReadMore = false;

            newString = widget.text;
          }
          break;
        default:
          newString = widget.text;
      }

      // Seperate each word and create a new Array

      TextStyle? style = widget.style;

      Map<String, MatchText> _mapping = Map<String, MatchText>();

      widget.parse.forEach((e) {
        if (e.type == ParsedType.EMAIL) {
          _mapping[emailPattern] = e;
        } else if (e.type == ParsedType.PHONE) {
          _mapping[phonePattern] = e;
        } else if (e.type == ParsedType.URL) {
          _mapping[urlPattern] = e;
        } else {
          _mapping[e.pattern!] = e;
        }
      });

      final pattern = '(${_mapping.keys.toList().join('|')})';

      List<InlineSpan> widgets = [];
      var isMultiLine = widget.regexOptions.multiLine;
      var isCaseSensitive = widget.regexOptions.caseSensitive;
      var isDotAll = widget.regexOptions.dotAll;
      var isUnicode = widget.regexOptions.unicode;

      newString.splitMapJoin(
        RegExp(
          pattern,
          multiLine: isMultiLine,
          caseSensitive: isCaseSensitive,
          dotAll: isDotAll,
          unicode: isUnicode,
        ),
        onMatch: (Match match) {
          final matchText = match[0];

          final mapping = _mapping[matchText!] ??
              _mapping[_mapping.keys.firstWhere((element) {
                final reg = RegExp(
                  element,
                  multiLine: isMultiLine,
                  caseSensitive: isCaseSensitive,
                  dotAll: isDotAll,
                  unicode: isUnicode,
                );
                return reg.hasMatch(matchText);
              }, orElse: () {
                return '';
              })];

          InlineSpan widget;

          if (mapping != null) {
            if (mapping.renderText != null) {
              Map<String, String> result =
                  mapping.renderText!(str: matchText, pattern: pattern);

              widget = TextSpan(
                text: "${result['display']}",
                style: mapping.style != null ? mapping.style : style,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => mapping.onTap!(matchText),
              );
            } else if (mapping.renderWidget != null) {
              widget = WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: GestureDetector(
                  onTap: () => mapping.onTap!(matchText),
                  child: mapping.renderWidget!(
                      text: matchText, pattern: mapping.pattern!),
                ),
              );
            } else {
              widget = TextSpan(
                text: "$matchText",
                style: mapping.style != null ? mapping.style : style,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => mapping.onTap!(matchText),
              );
            }
          } else {
            widget = TextSpan(
              text: "$matchText",
              style: style,
            );
          }

          widgets.add(widget);

          return '';
        },
        onNonMatch: (String text) {
          widgets.add(TextSpan(
            text: "$text",
            style: style,
          ));

          return '';
        },
      );

      if (widget.selectable) {
        return SelectableText.rich(
          TextSpan(children: <InlineSpan>[...widgets], style: style),
          maxLines: widget.maxLines,
          strutStyle: widget.strutStyle,
          textWidthBasis: widget.textWidthBasis,
          textAlign: widget.alignment,
          textDirection: widget.textDirection,
          onTap: widget.onTap as void Function()?,
        );
      }

      // return RichText(
      //   softWrap: widget.softWrap,
      //   overflow: widget.overflow,
      //   textScaleFactor: widget.textScaleFactor,
      //   maxLines: widget.maxLines,
      //   strutStyle: widget.strutStyle,
      //   textWidthBasis: widget.textWidthBasis,
      //   textAlign: widget.alignment,
      //   textDirection: widget.textDirection,
      //   text: TextSpan(
      //     text: '',
      //     children: <InlineSpan>[...widgets],
      //     style: style,
      //   ),
      // );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          RichText(
            softWrap: widget.softWrap,
            overflow: widget.overflow,
            textScaleFactor: widget.textScaleFactor,
            maxLines: widget.maxLines,
            strutStyle: widget.strutStyle,
            textWidthBasis: widget.textWidthBasis,
            textAlign: widget.alignment,
            textDirection: widget.textDirection,
            text: TextSpan(
              text: '',
              children: <InlineSpan>[...widgets],
              style: style,
            ),
          ),
          widget.isLoadMore && isShowReadMore
              ? InkWell(
                  onTap: _onTapLink,
                  child: !_readMore
                      ? Text(
                          widget.trimExpandedText,
                          style: widget.lessStyle,
                        )
                      : Text(
                          widget.trimCollapsedText,
                          style: widget.moreStyle,
                        ),
                )
              : Container(),
        ],
      );
    });

    if (widget.semanticsLabel != null) {
      result = Semantics(
        textDirection: widget.textDirection,
        label: widget.semanticsLabel,
        child: ExcludeSemantics(
          child: result,
        ),
      );
    }
    return result;
  }
}
