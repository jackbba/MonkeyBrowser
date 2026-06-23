// ==UserScript==
// @name         MonkeyBrowser 字幕助手
// @namespace    https://monkeybrowser.app
// @version      1.0
// @description  从网页提取字幕并传递到MonkeyBrowser播放器
// @author       MonkeyBrowser
// @match        *://*/*
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function() {
    'use strict';

    // 等待MonkeyBrowser就绪
    function waitForBridge(callback) {
        if (window.MonkeyBrowserSubtitle) {
            callback();
        } else {
            document.addEventListener('monkeyBrowserReady', callback);
        }
    }

    // 从页面提取字幕
    function extractSubtitlesFromPage() {
        const subtitles = [];

        // 方法1: 从 <track> 标签提取
        const tracks = document.querySelectorAll('track[kind="subtitles"], track[kind="captions"]');
        tracks.forEach(track => {
            if (track.src) {
                console.log('[MonkeyBrowser] Found subtitle track:', track.src);
                window.MonkeyBrowserSubtitle.loadFromURL(track.src);
            }
        });

        // 方法2: 从 videojs 播放器提取
        if (window.videojs) {
            const players = document.querySelectorAll('.video-js');
            players.forEach(el => {
                const player = videojs(el.id());
                const tracks = player.textTracks();
                for (let i = 0; i < tracks.length; i++) {
                    if (tracks[i].cues) {
                        const entries = [];
                        for (let j = 0; j < tracks[i].cues.length; j++) {
                            const cue = tracks[i].cues[j];
                            entries.push({
                                start: cue.startTime,
                                end: cue.endTime,
                                text: cue.text
                            });
                        }
                        window.MonkeyBrowserSubtitle.addTimedEntries(entries, 'srt');
                    }
                }
            });
        }

        // 方法3: 从 DASH/HLS 字幕轨道提取
        if (window.MediaSource || window.Hls) {
            console.log('[MonkeyBrowser] Detected media player, checking for subtitles...');
        }

        // 方法4: 从自定义字幕容器提取
        const subtitleContainers = document.querySelectorAll('[class*="subtitle"], [class*="caption"], [id*="subtitle"]');
        subtitleContainers.forEach(container => {
            const text = container.innerText;
            if (text && text.length > 0) {
                console.log('[MonkeyBrowser] Found subtitle container:', text.substring(0, 50));
            }
        });
    }

    // 示例：添加SRT格式字幕
    function addExampleSRT() {
        const srtContent = `1
00:00:01,000 --> 00:00:04,000
这是第一行字幕

2
00:00:05,000 --> 00:00:08,000
这是第二行字幕

3
00:00:09,000 --> 00:00:12,000
MonkeyBrowser 支持油猴脚本字幕！`;

        window.MonkeyBrowserSubtitle.addSRT(srtContent, {
            language: 'zh',
            name: '示例中文字幕'
        });
    }

    // 示例：使用定时字幕条目
    function addExampleTimedSubtitles() {
        const entries = [
            { start: 0, end: 3, text: "Welcome to MonkeyBrowser" },
            { start: 3.5, end: 6, text: "支持油猴脚本" },
            { start: 7, end: 10, text: "支持VLC播放器" },
            { start: 11, end: 14, text: "支持画中画和小窗口" },
            { start: 15, end: 18, text: "字幕可以由脚本动态生成！" }
        ];

        window.MonkeyBrowserSubtitle.addTimedEntries(entries, 'srt');
    }

    // 暴露全局接口供其他脚本使用
    window.MonkeyBrowserSubtitleHelper = {
        // 从URL加载字幕
        loadSubtitle: function(url) {
            waitForBridge(() => {
                window.MonkeyBrowserSubtitle.loadFromURL(url);
            });
        },

        // 添加SRT字幕
        addSRT: function(content, options) {
            waitForBridge(() => {
                window.MonkeyBrowserSubtitle.addSRT(content, options);
            });
        },

        // 添加VTT字幕
        addVTT: function(content, options) {
            waitForBridge(() => {
                window.MonkeyBrowserSubtitle.addVTT(content, options);
            });
        },

        // 添加ASS字幕
        addASS: function(content, options) {
            waitForBridge(() => {
                window.MonkeyBrowserSubtitle.addASS(content, options);
            });
        },

        // 添加带时间轴的字幕
        addTimedSubtitles: function(entries, format) {
            waitForBridge(() => {
                window.MonkeyBrowserSubtitle.addTimedEntries(entries, format || 'srt');
            });
        },

        // 从当前页面提取字幕
        extractFromPage: function() {
            waitForBridge(() => {
                extractSubtitlesFromPage();
            });
        }
    };

    // 页面加载完成后尝试提取字幕
    waitForBridge(() => {
        console.log('[MonkeyBrowser] Subtitle helper loaded');
        extractSubtitlesFromPage();
    });

})();
