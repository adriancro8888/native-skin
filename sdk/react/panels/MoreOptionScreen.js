'use strict';

import React, { Component } from 'react';
import {
  Animated,
  Image,
  ListView,
  StyleSheet,
  Text,
  TouchableHighlight,
  View,
} from 'react-native';

var Log = require('../log');
var Utils = require('../utils');
var Constants = require('../constants');
var styles = Utils.getStyles(require('./style/moreOptionScreenStyles.json'));
var CollapsingBarUtils = require('../collapsingBarUtils');

var {
  BUTTON_NAMES,
  IMG_URLS,
} = Constants;

var dismissButtonSize = 20;

var MoreOptionScreen = React.createClass({
	propTypes: {
    height: React.PropTypes.number,
    onDismiss: React.PropTypes.func,
    onOptionButtonPress: React.PropTypes.func,
    config: React.PropTypes.object,
    controlBarWidth: React.PropTypes.number
	},

  getInitialState: function() {
    return {
      translateY: new Animated.Value(this.props.height),
      opacity: new Animated.Value(0),
      buttonOpacity: new Animated.Value(1),
      button: '',
    };
  },

  componentDidMount:function () {
    this.state.translateY.setValue(this.props.height);
    this.state.opacity.setValue(0);
    Animated.parallel([
      Animated.timing(
        this.state.translateY,
        {
          toValue: 0,
          duration: 700,
          delay: 0
        }),
      Animated.timing(
        this.state.opacity,
        {
          toValue: 1,
          duration: 500,
          delay: 0
        }),
    ]).start();
  },

  onOptionBtnPressWithPanel: function() {
    this.props.onOptionButtonPress(this.state.button);
  },

  onOptionPress: function(buttonName) {
    if (BUTTON_NAMES.SHARE === buttonName) {
      this.props.onOptionButtonPress(buttonName);
    } else {
      this.setState({button: buttonName});
      Animated.timing(
        this.state.buttonOpacity,
        {
          toValue: 0,
          duration: 200,
          delay: 0
        }
      ).start(this.onOptionBtnPressWithPanel);
    }
  },

  onDismissBtnPress: function() {
    this.props.onDismiss();
  },

  onDismissPress: function(){
    Animated.timing(
      this.state.opacity,
      {
        toValue: 0,
        duration: 500,
        delay: 0
      }
    ).start(this.onDismissBtnPress);
  },

  _renderMoreOptionButtons: function(moreOptionButtons){
    var itemCollapsingResults = CollapsingBarUtils.collapse( this.props.config.controlBarWidth, this.props.config.buttons );
    var buttons = itemCollapsingResults.overflow;
    for(var i = 0; i < buttons.length; i++){
      var button = buttons[i];

      var moreOptionButton;
      var buttonIcon = this._renderIcon(button.name);
      var buttonStyle = [styles.icon, this.props.config.moreOptionsScreen.iconStyle.active];

      // If a color style exists, we remove it as it is applied to a view, which doesn't support
      // text color modification. Color key only applies to Text views.
      // Deleting the color key removes unwanted warnings in the app.
      if (buttonStyle[1].color) {
        delete buttonStyle[1].color;
      }

      // Skip unsupported buttons to avoid crashes. But log that they were unexpected.
      if (buttonIcon === undefined || buttonStyle === undefined ) {
        Log.warn( "Warning: skipping unsupported More Options button ", button );
        continue;
      }

      var onOptionPress = function(buttonName, f){
        return function(){
          f(buttonName);
        };
      }(button.name, this.onOptionPress);

      moreOptionButton = Utils.renderRectButton(button.name, buttonStyle, buttonIcon.fontString, onOptionPress, this.props.config.moreOptionsScreen.iconSize, this.props.config.moreOptionsScreen.color, buttonIcon.fontFamilyName, i);

      moreOptionButtons.push(moreOptionButton);
    }
  },

  _renderIcon: function(buttonName){
    var buttonIcon;
    switch(buttonName){
      case BUTTON_NAMES.DISCOVERY:
        buttonIcon = this.props.config.icons.discovery;
        break;
      case BUTTON_NAMES.QUALITY:
        buttonIcon = this.props.config.icons.quality;
        break;
      case BUTTON_NAMES.CLOSED_CAPTIONS:
        buttonIcon = this.props.config.icons.cc;
        break;
      case BUTTON_NAMES.SHARE:
        buttonIcon = this.props.config.icons.share;
        break;
      case BUTTON_NAMES.SETTING: // TODO: this doesn't exist in the skin.json?
        buttonIcon = this.props.config.icons.setting;
        break;
      default:
        break;
    }
    return buttonIcon;
  },

	render: function() {
    var moreOptionButtons = [];
    this._renderMoreOptionButtons(moreOptionButtons);
    var dismissButton = Utils.renderRectButton(BUTTON_NAMES.DISMISS, styles.iconDismiss, this.props.config.icons.dismiss.fontString, this.onDismissPress, dismissButtonSize, this.props.config.moreOptionsScreen.color, this.props.config.icons.dismiss.fontFamilyName);

    var moreOptionRow;
    var rowAnimationStyle = {transform:[{translateY:this.state.translateY}], opacity: this.state.buttonOpacity};
  
    moreOptionRow = (
    <Animated.View
      ref='moreOptionRow'
      style={[styles.rowCenter, rowAnimationStyle]}>
      {moreOptionButtons}
    </Animated.View>);
  
    var dismissButtonRow = (
      <View style={styles.dismissButtonTopRight}>
        {dismissButton}
      </View>
    );
    var animationStyle = {opacity:this.state.opacity};
    var moreOptionScreen = (
      <Animated.View style={[styles.fullscreenContainer, animationStyle]}>
        {moreOptionRow}
        {dismissButtonRow}
      </Animated.View>
    );

    return moreOptionScreen;
  }
});

module.exports = MoreOptionScreen;
