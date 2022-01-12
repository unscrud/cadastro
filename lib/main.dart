import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //retirar o banner de debug
      debugShowCheckedModeBanner: false,
      title: 'Cadastro',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _aniversarioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  CollectionReference _pessoas =
      FirebaseFirestore.instance.collection("pessoa");

  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _nomeController.text = documentSnapshot['nome'];
      _aniversarioController.text = documentSnapshot['aniversario'];
      _emailController.text = documentSnapshot['email'];
    }

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nomeController,
                  decoration: InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  keyboardType: TextInputType.datetime,
                  controller: _aniversarioController,
                  decoration: InputDecoration(
                    labelText: 'Data de Aniversário',
                  ),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'E-mail'),
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Criar' : 'Alterar'),
                  onPressed: () async {
                    final String nome = _nomeController.text;
                    final String data = _aniversarioController.text;
                    final String email = _emailController.text;
                    if (nome != null && data != null && email != null) {
                      if (action == 'create') {
                        await _pessoas.add({
                          "nome": nome,
                          "aniversario": data,
                          "email": email
                        });
                      }

                      if (action == 'update') {
                        await _pessoas.doc(documentSnapshot?.id).update({
                          "nome": nome,
                          "aniversario": data,
                          "email": email
                        });
                      }

                      _nomeController.text = '';
                      _aniversarioController.text = '';
                      _emailController.text = '';

                      Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  Future<void> _deletePerson(String pessoaId) async {
    await _pessoas.doc(pessoaId).delete();

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Pessoa excluída com sucesso!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CRUD Básico')),
      body: StreamBuilder<dynamic>(
        stream: _pessoas.snapshots(),
        builder: (context, streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data.docs[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(documentSnapshot['nome']),
                    subtitle: Text(documentSnapshot['email']),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _createOrUpdate(documentSnapshot),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deletePerson(documentSnapshot.id),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: Icon(Icons.add),
      ),
    );
  }
}
