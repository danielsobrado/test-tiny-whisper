# Project Overview

## Purpose
Tiny Whisper Tester is a Flutter Android application for testing different fine-tuned Whisper Tiny models for offline speech-to-text transcription on mobile devices. Users can download GGML models from HuggingFace URLs and test them with microphone input.

## Key Features
- Download Whisper GGML models from HuggingFace URLs
- Record audio using device microphone (16kHz mono WAV format optimized for Whisper)
- Test speech-to-text transcription offline on mobile devices
- Progress tracking for model downloads
- Audio recording management and cleanup

## Current Status
- **Whisper Integration**: Currently uses placeholder/mock implementation
- **Platform Support**: Android only (iOS not yet implemented)
- **Model Format**: Expects GGML .bin files from whisper.cpp
- **Real Implementation Needed**: Requires integration with whisper.cpp Flutter plugin or FFI bindings

## Target Users
Developers and researchers testing fine-tuned Whisper models on mobile devices for offline speech recognition applications.
