import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Model/user_client_search.dart';
import 'package:eshop_multivendor/Provider/UserClientSearchProvider.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchUserClientWidget extends StatelessWidget {
  final ValueChanged<UserClient?>? onUserSelected;

  const SearchUserClientWidget({
    super.key,
    this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    final userIdErp = context.read<UserProvider>().userIdErp;

    // Solo mostrar si userIdErp es diferente de null y diferente de 0
    if (userIdErp == null || userIdErp == 0) {
      return const SizedBox.shrink();
    }

    return ChangeNotifierProvider(
      create: (_) => UserClientSearchProvider(),
      child: _SearchUserClientBody(onUserSelected: onUserSelected),
    );
  }
}

class _SearchUserClientBody extends StatefulWidget {
  final ValueChanged<UserClient?>? onUserSelected;

  const _SearchUserClientBody({this.onUserSelected});

  @override
  State<_SearchUserClientBody> createState() => _SearchUserClientBodyState();
}

class _SearchUserClientBodyState extends State<_SearchUserClientBody> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
      context.read<UserClientSearchProvider>().hideResults();
    }
  }

  void _onUserSelected(UserClient user) {
    _removeOverlay();
    context.read<UserClientSearchProvider>().selectUser(user);
    _focusNode.unfocus();
    widget.onUserSelected?.call(user);
  }

  void _onClearSearch() {
    _removeOverlay();
    context.read<UserClientSearchProvider>().clearSearch();
    widget.onUserSelected?.call(null);
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 16, // Restamos el padding horizontal (8 + 8)
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -8), // Justo arriba del TextField con pequeño gap
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          child: Material(
            color: Colors.transparent,
            child: ChangeNotifierProvider.value(
              value: this.context.read<UserClientSearchProvider>(),
              child: Consumer<UserClientSearchProvider>(
                builder: (context, provider, _) {
                  if (!provider.showResults) {
                    return const SizedBox.shrink();
                  }
                  return _buildResultsContainer(provider);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserClientSearchProvider>(
      builder: (context, provider, _) {
        // Manejar overlay según showResults
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (provider.showResults && _overlayEntry == null) {
            _showOverlay();
          } else if (!provider.showResults && _overlayEntry != null) {
            _removeOverlay();
          } else if (provider.showResults && _overlayEntry != null) {
            _overlayEntry!.markNeedsBuild();
          }
        });

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: _buildSearchField(provider),
          ),
        );
      },
    );
  }

  Widget _buildSearchField(UserClientSearchProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: provider.searchController,
        focusNode: _focusNode,
        onChanged: provider.onTextChanged,
        style: TextStyle(
          fontFamily: 'ubuntu',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: colorScheme.fontColor,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar cliente por nombre...',
          hintStyle: TextStyle(
            fontFamily: 'ubuntu',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: colorScheme.lightBlack2,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.person_search_rounded,
              color: _getPrefixColor(provider.prefixState, colorScheme),
              size: 24,
            ),
          ),
          suffixIcon: _buildSuffixIcon(provider),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.gray,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: colors.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: colorScheme.white,
        ),
      ),
    );
  }

  Color _getPrefixColor(SearchPrefixState state, ColorScheme colorScheme) {
    switch (state) {
      case SearchPrefixState.found:
        return colors.primary;
      case SearchPrefixState.notFound:
        return colors.secondary;
      case SearchPrefixState.normal:
        return colorScheme.lightBlack2;
    }
  }

  Widget? _buildSuffixIcon(UserClientSearchProvider provider) {
    switch (provider.iconState) {
      case SearchIconState.normal:
        return null;

      case SearchIconState.loading:
        return Container(
          padding: const EdgeInsets.all(12),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colors.primary,
            ),
          ),
        );

      case SearchIconState.clear:
        return Container(
          margin: const EdgeInsets.only(right: 4),
          child: IconButton(
            onPressed: _onClearSearch,
            style: IconButton.styleFrom(
              backgroundColor: colors.red.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(
              Icons.close_rounded,
              color: colors.red,
              size: 20,
            ),
          ),
        );
    }
  }

  Widget _buildResultsContainer(UserClientSearchProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: colorScheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: colorScheme.gray,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildResultsContent(provider),
      ),
    );
  }

  Widget _buildResultsContent(UserClientSearchProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    // Loading
    if (provider.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Buscando clientes...',
              style: TextStyle(
                fontFamily: 'ubuntu',
                fontSize: 13,
                color: colorScheme.lightBlack2,
              ),
            ),
          ],
        ),
      );
    }

    // Error
    if (provider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.errorMessage!,
                style: TextStyle(
                  fontFamily: 'ubuntu',
                  fontSize: 14,
                  color: colorScheme.fontColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No hay resultados
    if (provider.users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_off_rounded,
                color: colors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cliente no encontrado',
                    style: TextStyle(
                      fontFamily: 'ubuntu',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.fontColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Intenta con otro nombre',
                    style: TextStyle(
                      fontFamily: 'ubuntu',
                      fontSize: 12,
                      color: colorScheme.lightBlack2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Lista de resultados
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: provider.users.length,
      itemBuilder: (context, index) {
        final user = provider.users[index];
        return _buildUserItem(user, colorScheme);
      },
    );
  }

  Widget _buildUserItem(UserClient user, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => _onUserSelected(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [colors.grad1Color, colors.grad2Color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  (user.username?.isNotEmpty == true)
                      ? user.username![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontFamily: 'ubuntu',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.whiteTemp,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username ?? '',
                    style: TextStyle(
                      fontFamily: 'ubuntu',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.fontColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.customerIdErp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${user.customerIdErp}',
                      style: TextStyle(
                        fontFamily: 'ubuntu',
                        fontSize: 12,
                        color: colorScheme.lightBlack2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.lightBlack2,
            ),
          ],
        ),
      ),
    );
  }
}
