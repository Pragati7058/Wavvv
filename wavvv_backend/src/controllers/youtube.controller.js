const axios = require('axios');
const config = require('../config/env');

const MOCK_VIDEOS = [
  {
    id: { videoId: 'jfKfPfyJRdk' },
    snippet: {
      title: 'lofi hip hop radio 🌌 beats to relax/study to',
      channelTitle: 'Lofi Girl',
      thumbnails: {
        medium: { url: 'https://img.youtube.com/vi/jfKfPfyJRdk/0.jpg' },
        high: { url: 'https://img.youtube.com/vi/jfKfPfyJRdk/0.jpg' },
      },
    },
  },
  {
    id: { videoId: '5qap5aO4i9A' },
    snippet: {
      title: 'Lofi Hip Hop Radio 🐾 Beats to Sleep/Chill to',
      channelTitle: 'Lofi Girl',
      thumbnails: {
        medium: { url: 'https://img.youtube.com/vi/5qap5aO4i9A/0.jpg' },
        high: { url: 'https://img.youtube.com/vi/5qap5aO4i9A/0.jpg' },
      },
    },
  },
  {
    id: { videoId: '2g811Eo7K8U' },
    snippet: {
      title: 'Deep Focus Ambient Music 🌧️ Rain Sound Overlay',
      channelTitle: 'Ambient Worlds',
      thumbnails: {
        medium: { url: 'https://img.youtube.com/vi/2g811Eo7K8U/0.jpg' },
        high: { url: 'https://img.youtube.com/vi/2g811Eo7K8U/0.jpg' },
      },
    },
  },
  {
    id: { videoId: 'tntOCGkgt98' },
    snippet: {
      title: 'Marvel Studios Avengers: Endgame - Official Trailer',
      channelTitle: 'Marvel Entertainment',
      thumbnails: {
        medium: { url: 'https://img.youtube.com/vi/tntOCGkgt98/0.jpg' },
        high: { url: 'https://img.youtube.com/vi/tntOCGkgt98/0.jpg' },
      },
    },
  },
  {
    id: { videoId: '1F3HMVqZ-Jg' },
    snippet: {
      title: 'Relaxing Rain Sounds for Sleep & Study 🌧️ 1 Hour Nature Ambient',
      channelTitle: 'The Rain Channel',
      thumbnails: {
        medium: { url: 'https://img.youtube.com/vi/1F3HMVqZ-Jg/0.jpg' },
        high: { url: 'https://img.youtube.com/vi/1F3HMVqZ-Jg/0.jpg' },
      },
    },
  },
];

const searchVideos = async (req, res, next) => {
  try {
    const { q } = req.query;
    if (!q) {
      return res.status(400).json({ error: 'Search query is required.' });
    }

    if (config.youtubeApiKey === 'MOCK_YOUTUBE_API_KEY') {
      // Filter mock results by query substring (case insensitive)
      const filtered = MOCK_VIDEOS.filter((vid) =>
        vid.snippet.title.toLowerCase().includes(q.toLowerCase()) ||
        vid.snippet.channelTitle.toLowerCase().includes(q.toLowerCase())
      );
      // Fallback to all mocks if no query match
      const results = filtered.length > 0 ? filtered : MOCK_VIDEOS;
      return res.status(200).json(results);
    }

    const response = await axios.get('https://www.googleapis.com/youtube/v3/search', {
      params: {
        part: 'snippet',
        maxResults: 15,
        q: q,
        type: 'video',
        key: config.youtubeApiKey,
      },
    });

    res.status(200).json(response.data.items);
  } catch (error) {
    console.error('YouTube Search API Error:', error.message);
    // If the request fails, return mock data instead of crashing the front-end
    res.status(200).json(MOCK_VIDEOS);
  }
};

const getVideoDetails = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!id) {
      return res.status(400).json({ error: 'Video ID is required.' });
    }

    if (config.youtubeApiKey === 'MOCK_YOUTUBE_API_KEY') {
      const found = MOCK_VIDEOS.find((vid) => vid.id.videoId === id);
      if (found) {
        return res.status(200).json(found);
      }
      return res.status(200).json({
        id: { videoId: id },
        snippet: {
          title: `Custom Watch Video (${id})`,
          channelTitle: 'Wavvv Custom Video',
          thumbnails: {
            medium: { url: `https://img.youtube.com/vi/${id}/0.jpg` },
            high: { url: `https://img.youtube.com/vi/${id}/0.jpg` },
          },
        },
      });
    }

    const response = await axios.get('https://www.googleapis.com/youtube/v3/videos', {
      params: {
        part: 'snippet,contentDetails',
        id: id,
        key: config.youtubeApiKey,
      },
    });

    if (!response.data.items || response.data.items.length === 0) {
      return res.status(404).json({ error: 'Video not found.' });
    }

    res.status(200).json(response.data.items[0]);
  } catch (error) {
    console.error('YouTube Video Info API Error:', error.message);
    res.status(200).json({
      id: { videoId: id },
      snippet: {
        title: `Mock Video (${id})`,
        channelTitle: 'Wavvv Watch Channel',
        thumbnails: {
          medium: { url: `https://img.youtube.com/vi/${id}/0.jpg` },
          high: { url: `https://img.youtube.com/vi/${id}/0.jpg` },
        },
      },
    });
  }
};

module.exports = {
  searchVideos,
  getVideoDetails,
};
