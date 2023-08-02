import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_music_background/pages/playlist_song_screen.dart';
import 'package:play_music_background/providers/music_provider.dart';
import 'package:play_music_background/services/service_locator.dart';
import 'package:play_music_background/utils/helper_functions.dart';
import 'package:provider/provider.dart';

import '../models/media_item_model.dart';

class PlaylistSongHomePage extends StatefulWidget {
  const PlaylistSongHomePage({super.key});

  @override
  State<PlaylistSongHomePage> createState() => _PlaylistSongHomePageState();
}

class _PlaylistSongHomePageState extends State<PlaylistSongHomePage> {
  static bool _isInitialized = false;
  final audioHandler = getIt<AudioHandler>();
  late MusicProvider musicProvider;

  final _formKey = GlobalKey<FormState>();
  ImageSource _imageSource = ImageSource.gallery;
  String? _artUri;

  //String _url = '';
  final albumController = TextEditingController();
  final titleController = TextEditingController();
  final urlController = TextEditingController();
  @override
  void initState() {
    if (!_isInitialized) {
      initProvider();
      if (kDebugMode) {
        print('Init method called only once');
        print('playList screen = ${audioHandler.queue.value}');
      }
      _isInitialized = true; // Set the flag to true after the setup
    }

    super.initState();
  }

  void initProvider() async {
    musicProvider = Provider.of<MusicProvider>(context, listen: false);
    await musicProvider.initialize();
    musicProvider.getAllSongs();
  }

  @override
  void dispose() {
    albumController.dispose();
    titleController.dispose();
    urlController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PlayList',style: TextStyle(color: Colors.black,),),actions: [
        IconButton(
          onPressed: () => _openAddDialog(context),
          icon: const Icon(
            Icons.add,
            color: Colors.black,
          ),
        ),
      ],
      leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.blue,
          ),
          onPressed: () {
            Navigator.pop(context);
            if (kDebugMode) {
              //print('Back to previous screen');
              print('Back to previous screen');
            }
          },
        ),),

      body:   Consumer<MusicProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            itemCount: provider.songs.length,
            itemBuilder: (context, index) {
              final song = provider.songs[index];
              return InkWell(
                onTap: () async {
                /*  File file = File(song.artUri);
                  // Create a Uri object from the file path using Uri.file constructor
                  Uri uri = Uri.file(file.path);
                  final newMediaItem = MediaItem(
                    id: song.id!.toString(),
                    title: song.title,
                    album: song.album,
                    extras: {
                      'url': song.url,
                      'isFile': true,
                    },
                    artUri: uri,
                  );
                  var pageManager = getIt<PageManager>();
                  pageManager.remove();
                  audioHandler.addQueueItem(newMediaItem);
                  pageManager.play();*/
                  if (mounted) {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PlaylistSongScreen(),
                      ),
                    );

                  }

                },
                child: ListTile(
                  leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: FileImage(
                        File(song.artUri),
                      )),
                  title: Text(song.title),
                  subtitle: Text(song.album),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_artUri == null) {
      showMsg(context, 'Please Select an Image');
      return;
    }
    if (_formKey.currentState!.validate()) {
      var songModel = SongModel(
        album: albumController.text,
        title: titleController.text,
        artUri: _artUri!,
        url: urlController.text,
      );
      final response = await musicProvider.addSong(songModel);
      if (response.statusCode == 200) {
        if (mounted) {
          showMsg(context, 'Successfully added a Ebook Audio');
        }
      } else {
        if (mounted) {
          showMsg(context, response.toString());
        }
      }
      _reset();
      setState(() {

      });
    }
  }

  Future<void> _getImage() async {
    final file =
    await ImagePicker().pickImage(source: _imageSource, imageQuality: 70);
    if (file != null) {
      setState(() {
        _artUri = file.path;
      });
    }
  }
  // Function to handle picking an audio file
  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        urlController.text = result.files.single.path ?? '';
      });
    } else {
      if (kDebugMode) {
        print('File Picker failed');
      }
    }
  }

  void _openAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context,setState) {
          return AlertDialog(
            title: const Text('Add AudioBook'),
            content: SingleChildScrollView(
              child: Column(
                //mainAxisSize: MainAxisSize.min,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      //crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: albumController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.album),
                            hintText: 'Album Name',
                            labelText: 'Album Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field must not be empty';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: titleController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.title),
                            hintText: 'Title Name',
                            labelText: 'Title Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field must not be empty';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: urlController,
                          readOnly: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.file_present),
                            hintText: 'Audio path',
                            labelText: 'Audio path',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field must not be empty';
                            }
                            return null;
                          },
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _pickAudio();
                          },
                          child: const Text('Pick Audio'),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Card(
                                  child: _artUri == null  || !File(_artUri!).existsSync()
                                      ? const Icon(
                                    Icons.photo,
                                    size: 100,
                                  )
                                      : Image.file(
                                    File(_artUri!),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  //mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        _imageSource = ImageSource.camera;
                                        await _getImage();
                                        setState(() {
                                        });
                                      },
                                      icon: const Icon(Icons.camera),
                                      label: const Text('Open Camera'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () async {
                                        _imageSource = ImageSource.gallery;
                                        await _getImage();
                                        setState(() {
                                        });
                                      },
                                      icon: const Icon(Icons.photo_album),
                                      label: const Text('Open Gallery'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _submitForm();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save'),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              )
            ],
          );

        });
      },
    );
  }

  void _reset() {
    albumController.text = '';
    titleController.text = '';
    urlController.text = '';
    _artUri = null;
  }
}
