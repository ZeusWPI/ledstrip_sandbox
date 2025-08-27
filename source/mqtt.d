module mqtt;

import data_dir : DataDir;
import mailbox : Mailbox;
import singleton : threadLocalSingleton;
import thread_manager : inMainThread;

import core.time : seconds;

import std.string : assumeUTF;
import std.utf : UTFException, validateUTF = validate;

import vibe.core.core : InterruptException, runTask, sleep;
import vibe.core.log;
import vibe.core.sync : createManualEvent, createSharedManualEvent, LocalManualEvent, ManualEvent;

import mqttd : ConnAck, MqttClient, Publish, QoSLevel, Settings, SubAck;

@safe:

final
class Mqtt
{
    mixin threadLocalSingleton;

    private static shared
    {
        ManualEvent g_onResubcribeRequest;
        Object g_newTopicsToSubMutex;
        string[] g_newTopicsToSub;
    }

    private string[] m_subscribedTopics;
    private LocalManualEvent m_onSubAckEvent;
    private const Settings m_mqttSettings;
    private MqttClient m_mqttClient;

    private
    this()
    in (inMainThread)
    {
        g_onResubcribeRequest = createSharedManualEvent;
        g_newTopicsToSubMutex = new shared Object;
        m_onSubAckEvent = createManualEvent;

        Settings settings;
        settings.host = DataDir.sharedConfig.mqttBrokerHost;
        settings.port = DataDir.sharedConfig.mqttBrokerPort;
        version (LedstripWs2811)       settings.clientId = "ledstrip";
        else version (LedstripVirtual) settings.clientId = "ledstrip-dev";
        else static assert(false);
        settings.reconnect = 1.seconds;
        settings.keepAlive = 5.seconds;
        settings.onConnAck = &onConnAck;
        settings.onPublish = &onPublish;
        settings.onSubAck = &onSubAck;
        m_mqttSettings = settings;
        m_mqttClient = new MqttClient(settings);
        m_mqttClient.connect;

        runTask(&subscriberTaskEntrypoint);
    }

    private
    ~this()
    {
        m_mqttClient.disconnect;
    }

    static
    void subscribe(string topic)
    {
        synchronized (g_newTopicsToSubMutex)
            g_newTopicsToSub ~= topic;
        g_onResubcribeRequest.emit;
    }

    private nothrow
    void subscriberTaskEntrypoint()
    {
        try
        {
            while (true)
            {
                g_onResubcribeRequest.wait;
                synchronized (g_newTopicsToSubMutex)
                {
                    if (m_mqttClient.connected && g_newTopicsToSub.length)
                    {
                        int emitCount = m_onSubAckEvent.emitCount;
                        m_mqttClient.subscribe(g_newTopicsToSub.idup, QoSLevel.QoS2);
                        if (emitCount == m_onSubAckEvent.emitCount)
                            m_onSubAckEvent.wait;
                    }
                    // Consume newTopicsToSub regardless, on (re)connect we'll sub to everything.
                    m_subscribedTopics ~= g_newTopicsToSub;
                    g_newTopicsToSub = [];
                }
            }
        }
        catch (InterruptException e)
            logError("Mqtt subscriber task interrupted");
        catch (Exception e)
            logError("Exception in mqtt subscriber task: %s", (() @trusted => e.toString)());
    }

    private nothrow
    void onConnAck(scope MqttClient client, in ConnAck packet)
    {
        try
        {
            logInfo("Connected to mqtt://%s:%s", m_mqttSettings.host, m_mqttSettings.port);
            synchronized (g_newTopicsToSubMutex)
                g_newTopicsToSub ~= m_subscribedTopics;
            m_subscribedTopics = [];
            g_onResubcribeRequest.emit;
        }
        catch (Exception e)
            logError("Exception in %s: %s", __FUNCTION__, (() @trusted => e.toString)());
    }

    private nothrow
    void onSubAck(scope MqttClient client, in SubAck packet)
    {
        m_onSubAckEvent.emit;
    }

    private nothrow
    void onPublish(scope MqttClient client, in Publish packet)
    {
        try
        {
            const(char)[] message = packet.payload.assumeUTF;
            validateUTF(message);
            Mailbox.instance.put(packet.topic, message.idup);
        }
        catch (UTFException e)
        {
            logError(
                "%s: Malformed UTF-8 message on topic %s: %s",
                __FUNCTION__, packet.topic, (() @trusted => e.toString)(),
            );
        }
        catch (Exception e)
        {
            logError("Exception in %s: %s", __FUNCTION__, (() @trusted => e.toString)());
        }
    }
}
