// Step 2: Install loading app screen
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
// Step 3: Check internet connection
import 'package:connectivity_plus/connectivity_plus.dart';
// Step 4: Show toast message
import 'package:fluttertoast/fluttertoast.dart';

// Step 6: Firestore CRUD operations
import 'package:cloud_firestore/cloud_firestore.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  @override
  // อะไรที่อยากให้ทำงานตอนเริ่มต้น ให้ใส่ในนี้
  void initState() {
    super.initState();

    // Step 3: Check internet connection
    checkInternetConnection();
  }

  // Step 3: Check internet connection
  void checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      // Mobile network available.
      _showToast(context, "Mobile network available.");
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      // Wi-fi is available.
      // Note for Android:
      // When both mobile and Wi-Fi are turned on system will return Wi-Fi only as active network type
      _showToast(context, "Wi-fi is available.");
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      // Ethernet connection available.
      _showToast(context, "Ethernet connection available.");
    } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
      // Vpn connection active.
      // Note for iOS and macOS:
      // There is no separate network interface type for [vpn].
      // It returns [other] on any device (also simulator)
      _showToast(context, "Vpn connection active.");
    } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
      // Bluetooth connection available.
      _showToast(context, "Bluetooth connection available.");
    } else if (connectivityResult.contains(ConnectivityResult.other)) {
      // Connected to a network which is not in the above mentioned networks.
      _showToast(context, "Other network is available.");
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      // No available network types
      setState(() {
        _showAlertDialog(
          context,
          "No Internet",
          "Please check your internet connection.",
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 49, 189, 72),
            Color.fromARGB(255, 33, 17, 208),
          ],
          begin: FractionalOffset(0, 0),
          end: FractionalOffset(0.5, 0.6),
          tileMode: TileMode.mirror,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Image.asset(
              './android/assets/image/screen.png',
              height: 100,
            ),
          ),
          const SizedBox(height: 20),
          const SpinKitSpinningLines(color: Colors.pinkAccent),
        ],
      ),
    );
  }
}

// Step 4: Show toast message
void _timer(BuildContext context) {
  // เมื่อรครบ 3 วิ ให้ไปหน้า SecondScreen
  Timer(
    const Duration(seconds: 3),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecondScreen()),
    ),
  );
}

// Step 4: Show toast message
void _showToast(BuildContext context, String msg) {
  Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.lightGreen,
    textColor: Colors.white,
    fontSize: 24.0,
  );
  _timer(context);
}

// Step 4: Show toast message
void _showAlertDialog(BuildContext context, String title, String msg) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.redAccent,
            fontWeight: FontWeight.w500,
            fontFamily: "Alike",
          ),
        ),
        content: Text(msg),
        actions: <Widget>[
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.black54),
            ),
            onPressed: () {
              Navigator.pop(context); // ถอยหลัง 1 หน้า
            },
            child: Text(
              "OK",
              style: TextStyle(
                fontSize: 20,
                color: Colors.blue.shade200,
                fontWeight: FontWeight.w500,
                fontFamily: "Alike",
              ),
            ),
          ),
        ],
      );
    },
  );
}

// class SecondScreen extends StatelessWidget {
//   const SecondScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Second Screen')),
//       body: const Center(
//         child: Text(
//           'This is the second screen',
//           style: TextStyle(
//             fontSize: 24,
//             color: Colors.amberAccent,
//             fontWeight: FontWeight.w500,
//             fontFamily: "Alike",
//           ),
//         ),
//       ),
//     );
//   }
// }

// Step 6: Firestore CRUD operations
// วางส่วนนี้ไว้ในไฟล์เดียวกับ FirstScreen แทน class SecondScreen เดิม

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker picker = ImagePicker();

  final TextEditingController animeNameController = TextEditingController();
  final TextEditingController episodeController = TextEditingController();
  final TextEditingController seasonController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<String?> _pickAndUploadImage() async {
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return null;

      final File file = File(picked.path);
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final Reference ref = storage.ref().child('anime_images/$fileName');

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snap = await uploadTask.whenComplete(() {});
      final String downloadUrl = await snap.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  void openAnimeBox(String? animeId) async {
    double scoreValue = 0.0;
    bool isUploading = false;

    if (animeId != null) {
      final doc = await firestore.collection('anime').doc(animeId).get();
      final data = doc.data();
      if (data != null) {
        animeNameController.text = data['animeName'] ?? '';
        episodeController.text = (data['episode'] ?? '').toString();
        seasonController.text = (data['season'] ?? '').toString();
        descriptionController.text = data['description'] ?? '';
        imageUrlController.text = data['imageUrl'] ?? '';
        scoreValue = _toDouble(data['score']);
      }
    } else {
      animeNameController.clear();
      episodeController.clear();
      seasonController.clear();
      descriptionController.clear();
      imageUrlController.clear();
      scoreValue = 0.0;
    }

    await showDialog(
      context: context,
      useSafeArea: true,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handlePickImage() async {
              setDialogState(() => isUploading = true);
              final url = await _pickAndUploadImage();
              setDialogState(() => isUploading = false);
              if (url != null) {
                imageUrlController.text = url;
                Fluttertoast.showToast(msg: "อัปโหลดรูปสำเร็จ");
              } else {
                Fluttertoast.showToast(msg: "อัปโหลดรูปไม่สำเร็จ");
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(16),
              title: Text(animeId == null ? 'เพิ่มอนิเมะ' : 'แก้ไขอนิเมะ'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: animeNameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่ออนิเมะ',
                        prefixIcon: Icon(Icons.movie),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: episodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ตอนที่',
                        prefixIcon: Icon(Icons.tv),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: seasonController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ซีซั่นที่',
                        prefixIcon: Icon(Icons.layers),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('คะแนน: ${scoreValue.toStringAsFixed(2)} / 5'),
                        Slider(
                          value: scoreValue,
                          onChanged: (v) => setDialogState(
                            () =>
                                scoreValue = double.parse(v.toStringAsFixed(2)),
                          ),
                          min: 0,
                          max: 5,
                          divisions: 50,
                          label: scoreValue.toStringAsFixed(2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียดสั้นๆ',
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: isUploading ? null : handlePickImage,
                          icon: const Icon(Icons.photo_library),
                          label: Text(
                            isUploading
                                ? 'กำลังอัปโหลด...'
                                : 'ใส่รูปจากเครื่อง',
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => imageUrlController.clear(),
                          icon: const Icon(Icons.clear),
                          label: const Text('ล้างรูป'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'หรือใส่ URL รูป (optional)',
                        prefixIcon: Icon(Icons.link),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('บันทึก'),
                  onPressed: () async {
                    final String name = animeNameController.text.trim();
                    final int episode =
                        int.tryParse(episodeController.text.trim()) ?? 0;
                    final int season =
                        int.tryParse(seasonController.text.trim()) ?? 0;
                    final double score = (scoreValue < 0)
                        ? 0
                        : (scoreValue > 5
                              ? 5
                              : double.parse(scoreValue.toStringAsFixed(2)));
                    final String description = descriptionController.text
                        .trim();
                    final String imageUrl = imageUrlController.text.trim();

                    if (name.isEmpty) {
                      Fluttertoast.showToast(msg: "กรุณากรอกชื่ออนิเมะ");
                      return;
                    }

                    final Map<String, dynamic> payload = {
                      'animeName': name,
                      'episode': episode,
                      'season': season,
                      'score': score,
                      'description': description,
                      'imageUrl': imageUrl,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (animeId == null) {
                      await firestore.collection('anime').add({
                        ...payload,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      Fluttertoast.showToast(msg: "เพิ่มอนิเมะเรียบร้อย");
                    } else {
                      await firestore
                          .collection('anime')
                          .doc(animeId)
                          .update(payload);
                      Fluttertoast.showToast(msg: "แก้ไขเรียบร้อย");
                    }

                    animeNameController.clear();
                    episodeController.clear();
                    seasonController.clear();
                    descriptionController.clear();
                    imageUrlController.clear();

                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(String animeId) async {
    final bool? res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบรายการนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (res == true) {
      await firestore.collection('anime').doc(animeId).delete();
      Fluttertoast.showToast(msg: "ลบเรียบร้อย");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text("Anime List"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => openAnimeBox(null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('anime')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'ยังไม่มีข้อมูลอนิเมะ',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String animeId = doc.id;
              final String name = data['animeName'] ?? '';
              final int episode = (data['episode'] ?? 0) is int
                  ? data['episode']
                  : int.tryParse(data['episode'].toString()) ?? 0;
              final int season = (data['season'] ?? 0) is int
                  ? data['season']
                  : int.tryParse(data['season'].toString()) ?? 0;
              final double score = _toDouble(data['score']);
              final String description = data['description'] ?? '';
              final String imageUrl = data['imageUrl'] ?? '';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 120,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 72,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('ตอนที่ $episode  •  ซีซั่น $season'),
                          const SizedBox(height: 8),
                          if (description.isNotEmpty)
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < score.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                          ),
                          Text('คะแนน: ${score.toStringAsFixed(2)} / 5'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => openAnimeBox(animeId),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(animeId),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
