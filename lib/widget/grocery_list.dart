import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widget/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  var _isLoading = true;
  String? _error;

  List<GroceryItem> _groceryItems = [];

  void _loadItems() async {
    final url = Uri.https(
        'flutter-prep-ee10f-default-rtdb.firebaseio.com', 'shopping-list.json');
    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data.Please try again later.';
        });
      }
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listData = json.decode(response.body);
      List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category));
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong!!Please try again later.';
        // print('error=$error');
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem groceryItem) async {
    final index = _groceryItems.indexOf(groceryItem);
    setState(() {
      _groceryItems.remove(groceryItem);
    });
    final url = Uri.https('flutter-prep-ee10f-default-rtdb.firebaseio.com',
        'shopping-list/${groceryItem.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Item removal failed ! '),
          duration: Duration(seconds: 3),
        ));
        _groceryItems.insert(index, groceryItem);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = ListView.builder(
      itemCount: _groceryItems.length,
      itemBuilder: ((context, index) => Dismissible(
            key: ValueKey(_groceryItems[index].id),
            onDismissed: (direction) {
              _removeItem(_groceryItems[index]);
            },
            child: ListTile(
              title: Text(_groceryItems[index].name),
              leading: Container(
                width: 24,
                height: 24,
                color: _groceryItems[index].category.color,
              ),
              trailing: Text(
                _groceryItems[index].quantity.toString(),
              ),
            ),
          )),
    );

    if (_groceryItems.isEmpty) {
      content = const Center(
        child: Text(
          'No items added yet. ',
          style: TextStyle(
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        body: content);
  }
}
