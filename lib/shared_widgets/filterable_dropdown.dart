import 'package:flutter/material.dart';

class FilterableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T item) getName;
  final dynamic Function(T item) getId; // Although not used in basic display, kept per requirement
  final void Function(T item) handleSelected;
  final String hintText;
  final T? initialItem;
  final VoidCallback? onClearSelected;

  const FilterableDropdown({
    super.key,
    required this.items,
    required this.getName,
    required this.getId,
    required this.handleSelected,
    this.hintText = 'Search...', // Default hint text
    this.initialItem,
    this.onClearSelected,
  });

  @override
  State<FilterableDropdown<T>> createState() => _FilterableDropdownState<T>();
}

class _FilterableDropdownState<T> extends State<FilterableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  List<T> _filteredItems = [];
  List<T> _sortedItems = [];
  bool _isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    _sortItems();
    _filteredItems = List.from(_sortedItems);

    if (widget.initialItem != null && widget.items.contains(widget.initialItem)) {
      _searchController.text = widget.getName(widget.initialItem!);
    }

    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _sortItems() {
    _sortedItems = List.from(widget.items);
    _sortedItems.sort((a, b) => widget.getName(a).toLowerCase().compareTo(widget.getName(b).toLowerCase()));
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _sortedItems
          .where((item) => widget.getName(item).toLowerCase().contains(query))
          .toList();
      if (_isOverlayVisible) {
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isOverlayVisible) {
      _showOverlay();
    } else if (!_focusNode.hasFocus && _isOverlayVisible) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    title: Text(widget.getName(item)),
                    onTap: () {
                      _selectItem(item);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() {
      _isOverlayVisible = true;
    });
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      setState(() {
        _isOverlayVisible = false;
      });
    }
  }

  void _selectItem(T item) {
    setState(() {
      _searchController.text = widget.getName(item);
      _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length));
      _onSearchChanged();
    });
    _removeOverlay();
    _focusNode.unfocus();
    widget.handleSelected(item);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: widget.hintText,
          suffixIcon: (_searchController.text.isNotEmpty && widget.onClearSelected != null)
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.onClearSelected!();
                    _searchController.clear();
                    _onSearchChanged(); // To reset filtered items
                    if (_isOverlayVisible) _removeOverlay();
                    _focusNode.unfocus(); // Optionally unfocus
                  },
                )
              : IconButton(
                  icon: Icon(_isOverlayVisible ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                  onPressed: () {
                    if (_isOverlayVisible) {
                      _removeOverlay();
                      _focusNode.unfocus();
                    } else {
                      // if (_focusNode.hasFocus) _removeOverlay(); // Keep overlay if already focused and shown by text input
                      _focusNode.requestFocus();
                      if (!_isOverlayVisible) _showOverlay(); // Ensure overlay shows if not already visible
                    }
                  },
                ),
        ),
      ),
    );
  }
}
