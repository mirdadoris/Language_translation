import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class LanguageTranslationPage extends StatefulWidget {
  const LanguageTranslationPage({Key? key});

  @override
  State<LanguageTranslationPage> createState() => _LanguageTranslationPageState();
}

class _LanguageTranslationPageState extends State<LanguageTranslationPage> {
  var languages = ['English', 'VietNam', 'China'];
  var originLanguage = "From";
  var destinationLanguage = "To";
  var output = "";
  TextEditingController languageController = TextEditingController();
  List<Map<String, String>> translationHistory = [];

  void translate(String src, String dest, String input) async {
    GoogleTranslator translator = GoogleTranslator();
    var translation = await translator.translate(input, from: src, to: dest);
    setState(() {
      output = translation.text.toString();
    });

    if (src == '--' || dest == '--') {
      setState(() {
        output = "Fail to translate";
      });
    }

    // Add translation to history with timestamp
    var now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    var translationRecord = {
      'Before': input,
      'After': output,
      'Time': now,
    };

    setState(() {
      translationHistory.add(translationRecord);
    });

    // Save to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('translationHistory') ?? [];
    history.add(json.encode(translationRecord));
    await prefs.setStringList('translationHistory', history);
  }

  String getLanguageCode(String language) {
    switch (language) {
      case "English":
        return "en";
      case "VietNam":
        return "vi";
      case "China":
        return "zh-cn";
      default:
        return "--";
    }
  }

  void showTranslationHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Translation History"),
              backgroundColor: Color(0xff3b413b),
              content: SizedBox(
                height: 300,
                width: 300,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: translationHistory.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Before: ${translationHistory[index]['Before']}"),
                                Text("After: ${translationHistory[index]['After']}"),
                                Text("Time: ${translationHistory[index]['Time']}"),
                                Divider(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Text(
                      'SoLan: ${translationHistory.length}',
                      style: TextStyle(color: Color(0xff00ffd1)),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          translationHistory.clear();
                        });
                      },
                      child: Text('Clear', style: TextStyle(color: Color(0xff00ffd1))),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Close', style: TextStyle(color: Color(0xff00ffd1))),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTranslationHistory();
  }

  void _loadTranslationHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? history = prefs.getStringList('translationHistory');
    if (history != null) {
      setState(() {
        translationHistory = history.map((e) => Map<String, String>.from(json.decode(e))).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff3b413b),
      appBar: AppBar(
        title: Text("Language Translator"),
        centerTitle: true,
        backgroundColor: Color(0xff00ffd1),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 50,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton(
                    focusColor: Colors.white,
                    iconDisabledColor: Colors.white,
                    iconEnabledColor: Colors.white,
                    hint: Text(
                      originLanguage, style: TextStyle(color: Colors.cyanAccent),
                    ),
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down),
                    items: languages.map((String dropDownStringItem){
                      return DropdownMenuItem(child: Text(dropDownStringItem),
                        value: dropDownStringItem,);
                    }).toList(),
                    onChanged: (String? value){
                      setState(() {
                        originLanguage = value!;
                      });
                    },
                  ),
                  SizedBox(width: 40,),
                  Icon(Icons.arrow_right_alt_outlined, color: Colors.cyanAccent, size: 40,),
                  SizedBox(width: 40,),
                  DropdownButton(
                    focusColor: Colors.white,
                    iconDisabledColor: Colors.white,
                    iconEnabledColor: Colors.white,
                    hint: Text(
                      destinationLanguage, style: TextStyle(color: Colors.cyanAccent),
                    ),
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down),
                    items: languages.map((String dropDownStringItem){
                      return DropdownMenuItem(child: Text(dropDownStringItem),
                        value: dropDownStringItem,);
                    }).toList(),
                    onChanged: (String? value){
                      setState(() {
                        destinationLanguage = value!;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 40,),
              Padding(padding: EdgeInsets.all(8),
                child: TextFormField(
                  cursorColor: Colors.white,
                  autofocus: false,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Please enter your text....',
                    labelStyle: TextStyle(fontSize: 15, color: Colors.white),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    errorStyle: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  controller: languageController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter text to translate';
                    }
                    return null;
                  },
                ),),
              Padding(padding: EdgeInsets.all(8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xff00ffd1)),
                  onPressed: (){
                    translate(getLanguageCode(originLanguage), getLanguageCode(destinationLanguage), languageController.text.toString());
                  },
                  child: Text("Translate"),
                ),
              ),
              SizedBox(height: 20,),
              ElevatedButton(
                style: ElevatedButton.styleFrom
                  (backgroundColor: Color(0xff00ffd1)),
                onPressed: showTranslationHistory,
                child: Text("History"),
              ),
              SizedBox(height: 20,),
              Text(
                "\n$output",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
