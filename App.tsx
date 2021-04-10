import React, {useState} from 'react';
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

const App = () => {
  const [recording, setRecording] = useState('');

  const fetchRecordings = () => {
    NativeModules.SharedFileSystemRCT.getAllFiles()
      .then(
        (
          retrievedRecordings: {absolutePath: string; relativePath: string}[],
        ) => {
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
  },
});

export default App;
