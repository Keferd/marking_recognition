import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для работы с буфером обмена


class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ResultScreen({super.key, required this.data});

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text:
        value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:
        Text('Скопировано: $value')));
  }

  Widget _buildDataCard(String title, String value, BuildContext context) {
    return Container(
      width:
          double.infinity, // Занять всю ширину экрана
      padding:
          const EdgeInsets.all(16),
      margin:
          const EdgeInsets.symmetric(vertical:
              8),
      decoration:
          BoxDecoration(
        color:
            Colors.blue[100],
        borderRadius:
            BorderRadius.circular(8),
        boxShadow:
            [
          BoxShadow(color:
              Colors.grey.withOpacity(0.5), blurRadius:
              5, spreadRadius:
              1),
        ],
      ),
      child:
          GestureDetector(
        onTap:
            () => _copyToClipboard(context,
                value),
        child:
            Text('$title : $value', style:
                const TextStyle(fontSize:
                16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title:
              const Text('Результаты')),
      body:
          Padding(padding:
              const EdgeInsets.all(16.0),
              child:
                  Center(child:
                      Column(crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children:
                              [
                                _buildDataCard('Деталь Артикул', data['ДетальАртикул'], context),
                                _buildDataCard('Порядковый Номер', data['ПорядковыйНомер'].toString(), context),
                                _buildDataCard('Деталь Наименование', data['ДетальНаименование'], context),
                                _buildDataCard('Заказ Номер', data['ЗаказНомер'], context),
                                _buildDataCard('Станция Блок', data['СтанцияБлок'], context),
                              ]
                      )
                  )
          )
    );
  }
}