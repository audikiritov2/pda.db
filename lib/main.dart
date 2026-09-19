import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

const String apiUrl = 'https://script.google.com/a/macros/spx-external.com/s/AKfycbwXBv7TurC0TlwojhHKFp2VW2AFsl7rT8W8bD--bZ37E6d4IdDACOiiLWh0BrsK2hMTIA/exec';

void main() => runApp(const PdaApp());

class PdaApp extends StatelessWidget {
  const PdaApp({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF155EEF), brightness: Brightness.light);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PDA Control',
      theme: ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, backgroundColor: Colors.white, surfaceTintColor: Colors.white),
        cardTheme: CardThemeData(elevation: 0, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.primary))),
      ),
      home: const HomePage(),
    );
  }
}

class Api {
  static Future<dynamic> get(String action, [Map<String, String>? q]) async {
    final uri = Uri.parse(apiUrl).replace(queryParameters: {'action': action, ...?q});
    final r = await http.get(uri).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final body = jsonDecode(r.body);
    if (body is Map && body['success'] == false) throw Exception('${body['message'] ?? 'API error'}');
    return body;
  }
  static Future<dynamic> post(String action, Map<String, dynamic> data) async {
    final r = await http.post(Uri.parse(apiUrl), body: {'action': action, 'data': jsonEncode(data)}).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final body = jsonDecode(r.body);
    if (body is Map && body['success'] == false) throw Exception('${body['message'] ?? 'API error'}');
    return body;
  }
  static List list(dynamic x) { final d = x is Map ? x['data'] : x; return d is List ? d : []; }
  static Map<String,dynamic> map(dynamic x) { final d = x is Map ? x['data'] : x; return d is Map ? Map<String,dynamic>.from(d) : {}; }
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState() => _HomePageState(); }
class _HomePageState extends State<HomePage> {
  int index = 0; Map<String,dynamic> dashboard = {}; bool loading = true; String? error;
  final pages = const [DashboardPage(), BorrowedPage(), PdaPage(), OpsPage()];
  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async { setState(()=>loading=true); try { dashboard=Api.map(await Api.get('dashboard')); error=null; } catch(e){ error='$e'; } finally { if(mounted)setState(()=>loading=false); } }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDA Control', style: TextStyle(fontWeight: FontWeight.w800)), actions:[IconButton(onPressed:_load, icon:const Icon(Icons.refresh))]),
      body: loading ? const Center(child:CircularProgressIndicator()) : error!=null ? ErrorView(message:error!, onRetry:_load) : IndexedStack(index:index, children:[DashboardPage(data:dashboard,onRefresh:_load), const BorrowedPage(), const PdaPage(), const OpsPage()]),
      bottomNavigationBar: NavigationBar(selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),destinations:const[
        NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'Dashboard'),
        NavigationDestination(icon:Icon(Icons.assignment_outlined),selectedIcon:Icon(Icons.assignment),label:'Dipinjam'),
        NavigationDestination(icon:Icon(Icons.devices_other_outlined),selectedIcon:Icon(Icons.devices_other),label:'PDA'),
        NavigationDestination(icon:Icon(Icons.person_search_outlined),selectedIcon:Icon(Icons.person_search),label:'OPS'),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ScanPage())),icon:const Icon(Icons.qr_code_scanner),label:const Text('SCAN')),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final Map<String,dynamic> data; final VoidCallback? onRefresh;
  const DashboardPage({super.key,this.data=const {},this.onRefresh});
  num n(String k)=>num.tryParse('${data[k] ?? 0}')??0;
  @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:() async=>onRefresh?.call(),child:ListView(padding:const EdgeInsets.fromLTRB(16,16,16,100),children:[
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[Color(0xFF155EEF),Color(0xFF4C7DFF)])),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Monitoring Operasional',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w800)),SizedBox(height:5),Text('Kontrol PDA • realtime dari Google Sheets',style:TextStyle(color:Colors.white70))])),
    const SizedBox(height:14),
    GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.45,children:[StatCard('Total PDA',n('total_pda'),Icons.devices),StatCard('Tersedia',n('tersedia'),Icons.check_circle),StatCard('Dipinjam',n('dipinjam'),Icons.person),StatCard('Total OPS',n('total_ops'),Icons.groups)]),
    const SizedBox(height:18),
    const SectionTitle('Menu Cepat'),
    ActionCard(icon:Icons.qr_code_scanner,title:'Scan QR PDA / OPS',subtitle:'Scan kode lalu pilih transaksi',onTap:null),
    ActionCard(icon:Icons.assignment_return,title:'Monitoring Peminjaman',subtitle:'Lihat PDA yang sedang dipakai',onTap:null),
    ActionCard(icon:Icons.table_chart,title:'Database Google Sheets',subtitle:'Transaksi tetap tersimpan di Peminjaman_PDA',onTap:null),
  ]));
}
class StatCard extends StatelessWidget { final String title; final num value; final IconData icon; const StatCard(this.title,this.value,this.icon,{super.key}); @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,size:25,color:Theme.of(c).colorScheme.primary),const Spacer(),Text(title,style:const TextStyle(fontSize:13)),Text('$value',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800))]))); }
class SectionTitle extends StatelessWidget { final String text; const SectionTitle(this.text,{super.key}); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Text(text,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800))); }
class ActionCard extends StatelessWidget { final IconData icon; final String title,subtitle; final VoidCallback? onTap; const ActionCard({super.key,required this.icon,required this.title,required this.subtitle,required this.onTap}); @override Widget build(BuildContext c)=>Card(child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:7),leading:CircleAvatar(child:Icon(icon)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right),onTap:onTap)); }

class BorrowedPage extends StatefulWidget { const BorrowedPage({super.key}); @override State<BorrowedPage> createState()=>_BorrowedPageState(); }
class _BorrowedPageState extends State<BorrowedPage>{ List items=[]; bool loading=true; String search=''; @override void initState(){super.initState();load();} Future<void>load()async{setState(()=>loading=true);try{items=Api.list(await Api.get('borrowed'));}catch(e){if(mounted)showSnack(context,'$e');}finally{if(mounted)setState(()=>loading=false);}} @override Widget build(BuildContext c){final filtered=items.where((x){final m=Map<String,dynamic>.from(x);final s='$m'.toLowerCase();return s.contains(search.toLowerCase());}).toList();return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.fromLTRB(12,14,12,100),children:[const SectionTitle('Sedang Dipinjam'),TextField(onChanged:(v)=>setState(()=>search=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari PDA, OPS, nama atau team')),const SizedBox(height:12),if(loading)const LinearProgressIndicator(),if(!loading&&filtered.isEmpty)const EmptyView(text:'Tidak ada PDA yang sedang dipinjam'),...filtered.map((x){final m=Map<String,dynamic>.from(x);final kode='${m['kode']??m['Kode_PDA']??'-'}';return Card(child:ListTile(leading:StatusIcon(borrowed:true),title:Text(kode,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${m['nama']??m['Nama']??'-'}\n${m['team']??m['Team']??'-'} • ${m['vendor']??m['Vendor']??'-'}'),isThreeLine:true,trailing:IconButton(tooltip:'Kembalikan',icon:const Icon(Icons.assignment_return),onPressed:()=>returnPda(c,m))));})]));}}
Future<void> returnPda(BuildContext c,Map m)async{final kode='${m['kode']??m['Kode_PDA']??''}';final condition=await showDialog<String>(context:c,builder:(_)=>ReturnDialog(kode:kode));if(condition==null)return;try{await Api.post('return',{'kode_pda':kode,'condition':condition,'notes':''});if(c.mounted)showSnack(c,'PDA $kode berhasil dikembalikan');(c.findAncestorStateOfType<_BorrowedPageState>())?.load();}catch(e){if(c.mounted)showSnack(c,'Gagal: $e');}}

class ReturnDialog extends StatefulWidget{final String kode;const ReturnDialog({super.key,required this.kode});@override State<ReturnDialog>createState()=>_ReturnDialogState();}
class _ReturnDialogState extends State<ReturnDialog>{String value='BAGUS';@override Widget build(BuildContext c)=>AlertDialog(title:Text('Kembalikan ${widget.kode}'),content:DropdownButtonFormField<String>(value:value,decoration:const InputDecoration(labelText:'Kondisi PDA'),items:const[DropdownMenuItem(value:'BAGUS',child:Text('Bagus')),DropdownMenuItem(value:'RUSAK',child:Text('Rusak')),DropdownMenuItem(value:'HILANG',child:Text('Hilang'))],onChanged:(v)=>setState(()=>value=v??'BAGUS')),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Batal')),FilledButton(onPressed:()=>Navigator.pop(c,value),child:const Text('Kembalikan'))]);}

class PdaPage extends StatefulWidget{const PdaPage({super.key});@override State<PdaPage>createState()=>_PdaPageState();}
class _PdaPageState extends State<PdaPage>{List items=[];bool loading=true;String search='';String filter='Semua';@override void initState(){super.initState();load();}Future<void>load()async{setState(()=>loading=true);try{items=Api.list(await Api.get('pda'));}catch(e){if(mounted)showSnack(context,'$e');}finally{if(mounted)setState(()=>loading=false);}}@override Widget build(BuildContext c){final filtered=items.where((x){final m=Map<String,dynamic>.from(x);final kode='${m['kode']??m['Kode_PDA']??''}';final status='${m['status']??m['STATUS']??''}';final okFilter=filter=='Semua'||(filter=='Tersedia'&&!status.toLowerCase().contains('pinjam'))||(filter=='Dipinjam'&&status.toLowerCase().contains('pinjam'));return okFilter&&('$kode $status $m'.toLowerCase().contains(search.toLowerCase()));}).toList();return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.fromLTRB(12,14,12,100),children:[const SectionTitle('Daftar PDA'),TextField(onChanged:(v)=>setState(()=>search=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Cari kode PDA')),const SizedBox(height:10),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:['Semua','Tersedia','Dipinjam'].map((x)=>Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(label:Text(x),selected:filter==x,onSelected:(_)=>setState(()=>filter=x)))).toList())),const SizedBox(height:12),if(loading)const LinearProgressIndicator(),if(!loading&&filtered.isEmpty)const EmptyView(text:'PDA tidak ditemukan'),...filtered.map((x){final m=Map<String,dynamic>.from(x);final kode='${m['kode']??m['Kode_PDA']??'-'}';final status='${m['status']??m['STATUS']??'-'}';final borrowed=status.toLowerCase().contains('pinjam');return Card(child:ListTile(leading:StatusIcon(borrowed:borrowed),title:Text(kode,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(status),trailing:borrowed?const Chip(label:Text('Dipinjam')):FilledButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>BorrowPage(kode:kode))),child:const Text('Pinjam'))));})]));}}

class OpsPage extends StatefulWidget{const OpsPage({super.key});@override State<OpsPage>createState()=>_OpsPageState();}
class _OpsPageState extends State<OpsPage>{final q=TextEditingController();List items=[];bool loading=false;Future<void>search()async{setState(()=>loading=true);try{items=Api.list(await Api.get('ops',{'q':q.text.trim()}));}catch(e){showSnack(context,'$e');}finally{if(mounted)setState(()=>loading=false);}}@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.fromLTRB(12,14,12,100),children:[const SectionTitle('Data OPS'),TextField(controller:q,onSubmitted:(_)=>search(),decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Cari OPS ID / nama / team',suffixIcon:IconButton(onPressed:search,icon:const Icon(Icons.search)))),const SizedBox(height:12),if(loading)const LinearProgressIndicator(),if(!loading&&items.isEmpty)const EmptyView(text:'Masukkan kata pencarian OPS'),...items.map((x){final m=Map<String,dynamic>.from(x);return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text('${m['nama']??m['Nama_OPS']??'-'}',style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${m['ops_id']??m['OPS_ID']??'-'} • ${m['vendor']??m['Vendor']??'-'}\nTeam: ${m['team']??m['Team']??'-'}'),isThreeLine:true));})]);}

class BorrowPage extends StatefulWidget{final String kode;const BorrowPage({super.key,required this.kode});@override State<BorrowPage>createState()=>_BorrowPageState();}
class _BorrowPageState extends State<BorrowPage>{final ops=TextEditingController();bool busy=false;Map found={};Future<void>find()async{if(ops.text.trim().isEmpty)return;try{found=Api.map(await Api.get('ops_detail',{'ops_id':ops.text.trim()}));if(found.isEmpty)showSnack(context,'OPS tidak ditemukan');setState((){});}catch(e){showSnack(context,'$e');}}Future<void>borrow()async{if(found.isEmpty){showSnack(context,'Cari OPS terlebih dahulu');return;}setState(()=>busy=true);try{await Api.post('borrow',{'ops_id':ops.text.trim(),'kode_pda':widget.kode});if(mounted){showSnack(context,'PDA ${widget.kode} berhasil dipinjam');Navigator.pop(context,true);}}catch(e){showSnack(context,'Gagal: $e');}finally{if(mounted)setState(()=>busy=false);}}@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text('Pinjam ${widget.kode}')),body:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Card(child:ListTile(leading:const Icon(Icons.devices),title:Text(widget.kode,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:const Text('PDA yang akan dipinjam'))),const SizedBox(height:12),TextField(controller:ops,keyboardType:TextInputType.number,textInputAction:TextInputAction.search,decoration:const InputDecoration(labelText:'OPS ID',prefixIcon:Icon(Icons.person_search)),onSubmitted:(_)=>find()),const SizedBox(height:10),OutlinedButton.icon(onPressed:find,icon:const Icon(Icons.search),label:const Text('CARI OPS')),if(found.isNotEmpty)Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text('${found['nama']??found['Nama_OPS']??'-'}'),subtitle:Text('${found['vendor']??found['Vendor']??'-'} • Team ${found['team']??found['Team']??'-'}'))),const Spacer(),SizedBox(height:52,child:FilledButton.icon(onPressed:busy?null:borrow,icon:const Icon(Icons.login),label:Text(busy?'MENYIMPAN...':'PINJAM PDA')))])));}

class ScanPage extends StatefulWidget{const ScanPage({super.key});@override State<ScanPage>createState()=>_ScanPageState();}
class _ScanPageState extends State<ScanPage>{bool done=false;@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Scan QR')),body:Stack(children:[MobileScanner(onDetect:(capture){if(done)return;final code=capture.barcodes.firstOrNull?.rawValue?.trim();if(code==null||code.isEmpty)return;done=true;Navigator.pushReplacement(c,MaterialPageRoute(builder:(_)=>ScanResultPage(code:code)));}),const Positioned(bottom:30,left:24,right:24,child:Card(color:Colors.black87,child:Padding(padding:EdgeInsets.all(14),child:Text('Arahkan kamera ke QR PDA atau OPS',textAlign:TextAlign.center,style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600))))) ]));}
class ScanResultPage extends StatelessWidget{final String code;const ScanResultPage({super.key,required this.code});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Hasil Scan')),body:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('Kode terbaca',style:TextStyle(color:Colors.grey)),const SizedBox(height:5),Text(code,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800)),const SizedBox(height:24),FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>BorrowPage(kode:code))),icon:const Icon(Icons.login),label:const Text('PINJAM PDA')),const SizedBox(height:10),OutlinedButton.icon(onPressed:()=>Navigator.pop(c),icon:const Icon(Icons.qr_code_scanner),label:const Text('SCAN LAGI'))])));}

class StatusIcon extends StatelessWidget{final bool borrowed;const StatusIcon({super.key,required this.borrowed});@override Widget build(BuildContext c)=>CircleAvatar(child:Icon(borrowed?Icons.person:Icons.check_circle));}
class EmptyView extends StatelessWidget{final String text;const EmptyView({super.key,required this.text});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(35),child:Center(child:Column(children:[Icon(Icons.inbox_outlined,size:50,color:Colors.grey.shade400),const SizedBox(height:8),Text(text,style:TextStyle(color:Colors.grey.shade600))])));}
class ErrorView extends StatelessWidget{final String message;final VoidCallback onRetry;const ErrorView({super.key,required this.message,required this.onRetry});@override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(25),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.cloud_off,size:55),const SizedBox(height:12),Text('Gagal mengambil data',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:6),Text(message,textAlign:TextAlign.center),const SizedBox(height:15),FilledButton.icon(onPressed:onRetry,icon:const Icon(Icons.refresh),label:const Text('Coba lagi'))])));}
void showSnack(BuildContext c,String text)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(text),behavior:SnackBarBehavior.floating));

