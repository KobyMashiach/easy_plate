import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../bloc/library_bloc.dart';
import '../widgets/book_cover_card.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LibraryBloc.fromContext(context),
      child: Scaffold(
        appBar: AppBar(title: Text(t.books.myLibrary)),
        // Builder so the dialog resolves LibraryBloc from below the provider,
        // and a unique heroTag so the tabs' FABs don't collide in the IndexedStack.
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            heroTag: 'libraryFab',
            onPressed: () => _showCreateBookDialog(context),
            child: const Icon(Icons.add),
          ),
        ),
        body: BlocBuilder<LibraryBloc, LibraryState>(
          builder: (context, state) {
            return switch (state) {
              LibraryLoading() => const Center(child: CircularProgressIndicator()),
              LibraryLoaded(books: final books) => books.isEmpty
                  ? Center(child: Text(t.books.emptyLibrary))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return BookCoverCard(
                          book: book,
                          onTap: () => context.pushNamed(Routing.bookDetails, extra: book.id),
                          onDelete: () => context.read<LibraryBloc>().add(.deleteBook(book.id)),
                        );
                      },
                    ),
              LibraryError(error: final error) => ErrorRetryView(
                  error: error,
                  onRetry: () => context.read<LibraryBloc>().add(const LibraryEvent.init()),
                ),
            };
          },
        ),
      ),
    );
  }

  void _showCreateBookDialog(BuildContext context) {
    final bloc = context.read<LibraryBloc>();
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.books.newBook),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.books.newBookTitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                bloc.add(.createBook(controller.text.trim()));
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(t.common.save),
          ),
        ],
      ),
    );
  }
}
