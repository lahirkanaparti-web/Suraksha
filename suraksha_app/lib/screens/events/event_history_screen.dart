import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {

  List logs = [];

  Future fetchLogs() async {

    final response = await http.get(
        Uri.parse("http://YOUR_DJANGO_SERVER/api/events/"));

    if(response.statusCode == 200){
      setState(() {
        logs = json.decode(response.body);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Event Logs")),

      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context,index){

          return ListTile(
            title: Text(logs[index]['event_type']),
            subtitle: Text(logs[index]['timestamp']),
          );
        },
      ),
    );
  }
}