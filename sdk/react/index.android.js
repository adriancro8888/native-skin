/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';

import React, { Component } from 'react';
import {
  AppRegistry,
  ActivityIndicator,
  StyleSheet,
  Text,
  TouchableHighlight,
  View,
  BackAndroid,
} from 'react-native';

var RCTDeviceEventEmitter = require('RCTDeviceEventEmitter');
var Log = require('./log');

//calling class layout controller
var eventBridge = require('NativeModules').OoyalaReactBridge;

var Constants = require('./constants');
var {
  SCREEN_TYPES,
  PLATFORMS,
  DESIRED_STATES
} = Constants;
var OoyalaSkinCore = require('./ooyalaSkinCore');
var OoyalaSkinCoreInstance;
var AccessibilityInfo = require("./accessibility/AccessibilityInfo");

var OoyalaSkin = React.createClass({
  // note/todo: some of these are more like props, expected to be over-ridden/updated
  // by the native bridge, and others are used purely on the non-native side.
  // consider using a leading underscore, or something?
  getInitialState: function() {
    return {
      // states from react
      screenType: SCREEN_TYPES.LOADING_SCREEN,
      overlayStack: [],
      // states from native
      title: '',
      description: '',
      cuePoints: [],
      promoUrl: '',
      hostedAtUrl: '',
      desiredState: DESIRED_STATES.DESIRED_PAUSE,
      playhead: 0,
      duration: 1,
      rate: 0,
      fullscreen: false,
      lastPressedTime: new Date(0),
      upNextDismissed: false,
      showPlayButton: true,
      // things which default to null and thus don't have to be stated:
      // selectedLanguage: null,
      // availableClosedCaptionsLanguages: null,
      alertTitle: '',
      alertMessage: '',
      error: null,
      platform:PLATFORMS.ANDROID,
      screenReaderEnabled: false,
    };
  },

  componentWillMount: function() {
    OoyalaSkinCoreInstance = new OoyalaSkinCore(this, eventBridge);
    OoyalaSkinCoreInstance.mount(RCTDeviceEventEmitter);
  },

  componentDidMount: function() {
    // eventBridge.queryState();
    BackAndroid.addEventListener('hardwareBackPress', function () {
      return OoyalaSkinCoreInstance.onBackPressed();
    });

    AccessibilityInfo.addEventListener(
      'change',
      this._handleScreenReaderToggled
    );
    AccessibilityInfo.fetch().done((isEnabled) => {
      this.setState({
        screenReaderEnabled: isEnabled
      });
    });
  },

  componentWillUnmount: function() {
    OoyalaSkinCoreInstance.unmount();

    AccessibilityInfo.removeEventListener(
      'change',
      this._handleScreenReaderToggled
    );
  },

  _handleScreenReaderToggled: function(isEnabled) {
    this.setState({
      screenReaderEnabled: isEnabled
    });
  },

  renderLoadingScreen: function() {
     return (
       <ActivityIndicator
        style={styles.loading}
        size="large"
      />
    );
  },

  renderVideoView: function() {
    return (
      <View style={styles.container}>
          <Text>{this.state.playerState}</Text>
      </View>);
  },

  render: function() {
    return OoyalaSkinCoreInstance.renderScreen();
  }
});

var styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'transparent',
  },
  loading: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    height: 200
  },
});

AppRegistry.registerComponent('OoyalaSkin', () => OoyalaSkin);
