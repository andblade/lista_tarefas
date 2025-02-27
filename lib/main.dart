import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoController = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState(){
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDO(){
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      
      _saveData();
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });

      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(children: <Widget>[
              
              Expanded(
                child: TextField(
                  controller: _toDoController,
                  decoration: InputDecoration(
                    labelText: "Nova tarefa",
                    labelStyle: TextStyle(color: Colors.blueAccent)
                  ),
                ),
              ),

              RaisedButton(
                onPressed: _addToDO,
                color: Colors.blueAccent,
                child: Text("ADD"),
                textColor: Colors.white,
              )

            ],),
          ),

          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                padding: EdgeInsets.only(top:10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem
              ), 
              onRefresh: _refresh,
            )
          )
        ],
      ),
    );
  }


  Widget buildItem(BuildContext context, int index){
    return Dismissible(
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color:Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      
      // ele precisa de uma 'chave individual' com um nome qualquer
      // e nesse caso usamos os 'milisegundos para diferencias cada tarefa
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),),
        onChanged: (check){
          setState(() {
            _toDoList[index]["ok"] = check;
            _saveData();
          });
        },
      ),
      onDismissed: (direction){
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa '${_lastRemoved["title"]}' removida"),
            action: SnackBarAction(
              label: "Desfazer", 
              onPressed: (){
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              }
            ),
            duration: Duration(seconds:4),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  // função para obter o arquivo
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  // função para salvar um dado no arquivo
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  // funação para ler os dados no arquivo
  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e){
      return null;
    }
  }


}