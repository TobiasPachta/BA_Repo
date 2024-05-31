using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Profiling;
using System.IO;



public class GameManager : MonoBehaviour
{
    ProfilerRecorder mainThreadTimeRecorder;
    ProfilerRecorder gpuThreadTimeRecorder;
    ProfilerRecorder systemMemoryRecorder;
    private string log_file_path;
    StreamWriter fileWriter;
    public GameObject platform_prefab;

    public int platform_count = 300;
    // Start is called before the first frame update
    void Start() {
        Vector3 spawn_position = new Vector3();
        float platform_x_position = -2.5f;
        for (int i = 0; i<platform_count;i++) {
            spawn_position.y += 1.5f;
            platform_x_position += 1.25f;
            if (platform_x_position >= 2.55f) {
                platform_x_position = -2.5f;
            }
            spawn_position.x = platform_x_position;
            Instantiate(platform_prefab, spawn_position, Quaternion.identity);
        }        
    }
    void Awake() {   
        //activate profiler
        FrameTimingManager.CaptureFrameTimings();
        //set log file path
        log_file_path = Application.persistentDataPath + "/out.txt";
        //create file writer for the whole testrun
        fileWriter = new StreamWriter(log_file_path,true);
        //create header for log file
        WriteToFile("CPU_ms;RAM_mb");
        //force fps to 60, virtual android devices can't reach more than 60hz, but default would be 30FPS
        Application.targetFrameRate = 60;
    }
    void OnEnable() {
        //create profilers for frame time and memory usage
        mainThreadTimeRecorder = ProfilerRecorder.StartNew(ProfilerCategory.Internal, "CPU Total Frame Time");
        systemMemoryRecorder = ProfilerRecorder.StartNew(ProfilerCategory.Memory, "System Used Memory");
        //print log message, will be read from android logcat 
        print($"Loading finished {(Time.realtimeSinceStartupAsDouble * 1000):F2}");
        Application.targetFrameRate = 60;
    }

    private void FixedUpdate() {
        //log performance metrics
        string measurement = "";
        measurement += $"{(mainThreadTimeRecorder.LastValue * (1e-6f)):F1};";
        measurement += $"{systemMemoryRecorder.LastValue / (1024 * 1024)};";
        WriteToFile(measurement);
    }
    void OnDisable() {
        // Recorders must be explicitly disposed after use
        mainThreadTimeRecorder.Dispose();
        systemMemoryRecorder.Dispose();
    }

    private void WriteToFile(string textToWrite) {
        //write line to log file
        fileWriter.WriteLine(textToWrite);
    }
}
