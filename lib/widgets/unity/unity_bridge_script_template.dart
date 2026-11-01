/// C# Bridge script template to be placed inside the Unity project:
/// `Assets/Scripts/FlutterUnityBridge.cs`
///
/// This script attaches to an empty GameObject named "FlutterManager"
/// and facilitates bidirectional communication with the Flutter app.
const String unityBridgeCSharpCode = r'''
using System;
using UnityEngine;
using UnityEngine.SceneManagement;

#if UNITY_ANDROID || UNITY_IOS
using System.Runtime.InteropServices;
#endif

namespace FlutterBridge
{
    [Serializable]
    public class FlutterMessagePayload
    {
        public string action;
        public string data;
    }

    public class FlutterUnityBridge : MonoBehaviour
    {
        public static FlutterUnityBridge Instance { get; private set; }

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
            }
        }

        private void Start()
        {
            // Notify Flutter that Unity engine is fully initialized and ready
            SendMessageToFlutter("onUnityReady", "{\"status\":\"ready\"}");
        }

        /// <summary>
        /// Invoked by Flutter via UnityPlayer.UnitySendMessage("FlutterManager", "OnFlutterMessage", json)
        /// </summary>
        public void OnFlutterMessage(string messageJson)
        {
            Debug.Log($"[FlutterUnityBridge] Message received from Flutter: {messageJson}");

            try
            {
                var payload = JsonUtility.FromJson<FlutterMessagePayload>(messageJson);
                HandleAction(payload.action, payload.data);
            }
            catch (Exception ex)
            {
                Debug.LogError($"[FlutterUnityBridge] Failed to parse message: {ex.Message}");
            }
        }

        private void HandleAction(string action, string data)
        {
            switch (action)
            {
                case "LOAD_SCENE":
                    SceneManager.LoadScene(data);
                    SendMessageToFlutter("onSceneLoaded", data);
                    break;

                case "RESTART_GAME":
                    SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
                    break;

                case "SET_PAUSED":
                    bool paused = bool.Parse(data);
                    Time.timeScale = paused ? 0f : 1f;
                    break;

                default:
                    Debug.Log($"[FlutterUnityBridge] Custom action: {action} with data: {data}");
                    break;
            }
        }

        /// <summary>
        /// Sends a JSON message back to Flutter
        /// </summary>
        public void SendMessageToFlutter(string methodName, string jsonMessage)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            using (var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            {
                var activity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity");
                activity.Call("onUnityMessage", $"{{\"method\":\"{methodName}\",\"data\":{jsonMessage}}}");
            }
#elif UNITY_IOS && !UNITY_EDITOR
            NativeApi.OnUnityMessage(methodName, jsonMessage);
#else
            Debug.Log($"[Editor/Mock] Sending message to Flutter: {methodName} -> {jsonMessage}");
#endif
        }
    }

#if UNITY_IOS
    internal static class NativeApi
    {
        [DllImport("__Internal")]
        internal static extern void OnUnityMessage(string methodName, string data);
    }
#endif
}
''';
