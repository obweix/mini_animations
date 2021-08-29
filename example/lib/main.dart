import 'package:flutter/material.dart';
import 'package:mini_animations/mini_animations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'animations test demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{
  late Animation<double> animation;
  late AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body:
        Center(
          child: Container(
            color: Colors.green,
            // width: animation.value,
            // height: animation.value,
            child: OpenContainerWrapper(
              openBuilder: (_,VoidCallback cb){
                return _DetailsPage();
              },
              closedBuilder: (_,VoidCallback cb){
                return Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 100,
                  color: Colors.blue,
                  child: Text("tap me"),
                );
              },
              onClosed: () {
                print("on close.");
              },
            ),
          ),
        )
    );
  }
}



class OpenContainerWrapper extends StatelessWidget {
  const OpenContainerWrapper({
    Key? key,
    required this.closedBuilder,
    required this.openBuilder,
    required this.onClosed
  }) : super(key: key);

  final Widget Function(BuildContext context, VoidCallback action) closedBuilder;
  final Widget Function(BuildContext context, VoidCallback action) openBuilder;
  final void Function() onClosed;

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      tappable: true,
      openBuilder: (context,VoidCallback _){
        return const _DetailsPage();
      },

      closedBuilder: closedBuilder,
      onClosed: onClosed,
      useRootNavigator: true,
    );
  }
}

const String _loremIpsumParagraph =
    '这几天心里颇不宁静。今晚在院子里坐着乘凉，忽然想起日日走过的荷塘，'
    '在这满月的光里，总该另有一番样子吧。月亮渐渐地升高了，墙外马路上孩子们的欢笑，'
    '已经听不见了；妻在屋里拍着闰儿，迷迷糊糊地哼着眠歌。我悄悄地披了大衫，带上门出去。'
    '沿着荷塘，是一条曲折的小煤屑路。这是一条幽僻的路；白天也少人走，夜晚更加寂寞。荷塘四面，'
    '长着许多树，蓊蓊郁郁的。路的一旁，是些杨柳，和一些不知道名字的树。没有月光的晚上，'
    '这路上阴森森的，有些怕人。今晚却很好，虽然月光也还是淡淡的。路上只我一个人，背着手踱着。'
    '这一片天地好像是我的；我也像超出了平常的自己，到了另一世界里。我爱热闹，也爱冷静；爱群居，也爱独处。'
    '像今晚上，一个人在这苍茫的月下，什么都可以想，什么都可以不想，便觉是个自由的人。';

class _DetailsPage extends StatelessWidget {
  const _DetailsPage({this.includeMarkAsDoneButton = true});

  final bool includeMarkAsDoneButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details page'),
        actions: <Widget>[
          if (includeMarkAsDoneButton)
            IconButton(
              icon: const Icon(Icons.done),
              onPressed: () => Navigator.pop(context, true),
              tooltip: 'Mark as done',
            )
        ],
      ),
      body: ListView(
        children: <Widget>[
          Container(
            color: Colors.black38,
            height: 250,
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Image.asset(
                'assets/Tom.png',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '荷塘月色',
                  style: Theme.of(context).textTheme.headline5!.copyWith(
                    color: Colors.black54,
                    fontSize: 30.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _loremIpsumParagraph,
                  style: Theme.of(context).textTheme.bodyText2!.copyWith(
                    color: Colors.black54,
                    height: 1.5,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

