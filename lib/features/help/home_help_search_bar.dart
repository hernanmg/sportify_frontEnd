import 'package:flutter/material.dart';

/// Barra de búsqueda deslizable para el AppBar del inicio.
class HomeHelpSearchBar extends StatefulWidget {
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<String> onSearch;

  const HomeHelpSearchBar({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
    required this.onSearch,
  });

  @override
  State<HomeHelpSearchBar> createState() => _HomeHelpSearchBarState();
}

class _HomeHelpSearchBarState extends State<HomeHelpSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant HomeHelpSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && !oldWidget.expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
    if (!widget.expanded && oldWidget.expanded) {
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final q = _controller.text.trim();
    widget.onSearch(q);
    widget.onExpandedChanged(false);
  }

  void _toggle() {
    widget.onExpandedChanged(!widget.expanded);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: widget.expanded
              ? MediaQuery.sizeOf(context).width.clamp(160, 220).toDouble()
              : 0,
          child: widget.expanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar ayuda…',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        suffixIcon: IconButton(
                          tooltip: 'Buscar',
                          icon: const Icon(Icons.arrow_forward, size: 20),
                          color: Colors.white,
                          onPressed: _submit,
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                )
              : null,
        ),
        IconButton(
          tooltip: widget.expanded ? 'Cerrar ayuda' : 'Ayuda',
          icon: Icon(
            widget.expanded ? Icons.close : Icons.help_outline,
            color: Colors.white,
          ),
          onPressed: _toggle,
        ),
      ],
    );
  }
}
