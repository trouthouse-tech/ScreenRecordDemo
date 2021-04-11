import React, {useEffect, useState} from 'react';
import {
  SafeAreaView,
  NativeModules,
  TouchableOpacity,
  Text,
  requireNativeComponent,
  StyleSheet,
} from 'react-native';
const RecordComponent = requireNativeComponent('RecordComponent');
import Video from 'react-native-video';
import RNFS from 'react-native-fs';

const App = () => {
  const [recording, setRecording] = useState('');

  useEffect(() => {
    if (recording !== '') {
      RNFS.stat(recording).then(stat => {
        console.log('stat: ', stat);
      });
      RNFS.readFile(recording).then(file => console.log('file: ', file));
    }
  }, [recording]);

  const fetchRecordings = () => {
    NativeModules.SharedFileSystemRCT.getAllFiles()
      .then(
        (
          retrievedRecordings: {absolutePath: string; relativePath: string}[],
        ) => {
          console.log('retrievedRecordings: ', retrievedRecordings);
          retrievedRecordings.map(item => {
            RNFS.stat(item.absolutePath).then(stat => {
              console.log('stat: ', stat);
            });
            RNFS.readFile(item.absolutePath).then(file =>
              console.log('file: ', file),
            );
          });
          setRecording(
            retrievedRecordings[retrievedRecordings.length - 1].absolutePath,
          );
        },
      )
      .catch((err: any) => console.log('err: ', err));
  };

  return (
    <SafeAreaView style={styles.container}>
      <RecordComponent style={styles.recordButton} />
      <TouchableOpacity
        onPress={() => fetchRecordings()}
        style={styles.fetchVideosButton}>
        <Text style={styles.fetchVideoText}>Retrieve videos</Text>
      </TouchableOpacity>
      {recording !== '' && (
        <Video
          source={{
            uri: recording,
          }}
          style={styles.video}
        />
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#ffffff',
    flex: 1,
  },
  recordButton: {
    width: 100,
    height: 100,
  },
  fetchVideosButton: {
    height: 100,
    width: 200,
    backgroundColor: 'grey',
    justifyContent: 'center',
    alignItems: 'center',
  },
  fetchVideoText: {
    color: '#ffffff',
  },
  video: {
    height: 400,
    width: 200,
    backgroundColor: '#d4d4d4',
  },
});

export default App;
