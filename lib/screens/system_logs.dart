import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SystemLogs extends StatelessWidget {
  final DatabaseReference _logsRef = FirebaseDatabase.instance.ref('logs');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logs del Sistema"),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _logsRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data!.snapshot.value;
          if (logs == null) {
            return Center(child: Text("No hay logs disponibles"));
          }

          final logsList = (logs as Map).values.toList();
          return ListView.builder(
            itemCount: logsList.length,
            itemBuilder: (context, index) {
              var log = logsList[index];
              return ListTile(
                title: Text(log['actividad']),
                subtitle: Text(log['fecha']),
              );
            },
          );
        },
      ),
    );
  }
}
