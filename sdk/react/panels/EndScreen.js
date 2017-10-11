import React, { Component } from "react";
import {
  StyleSheet,
  Text,
  View,
  Image,
  TouchableHighlight
} from "react-native";

var Utils = require("../utils");

var styles = Utils.getStyles(require("./style/endScreenStyles.json"));
var ProgressBar = require("../progressBar");
var ControlBar = require("../controlBar");
var WaterMark = require("../waterMark");
var InfoPanel = require("../infoPanel");
var BottomOverlay = require("../bottomOverlay");
var Log = require("../log");
var Constants = require("../constants");

var {
  BUTTON_NAMES,
  IMG_URLS
} = Constants;

var EndScreen = React.createClass({
	getInitialState: function() {
    return {
      showControls:true,
    };
  },

  propTypes: {
    config: React.PropTypes.object,
    title: React.PropTypes.string,
    duration: React.PropTypes.number,
    description: React.PropTypes.string,
    promoUrl: React.PropTypes.string,
    onPress: React.PropTypes.func,
    width: React.PropTypes.number,
    height: React.PropTypes.number,
    volume: React.PropTypes.number,
    upNextDismissed: React.PropTypes.bool,
    fullscreen: React.PropTypes.bool,
    handleControlsTouch: React.PropTypes.func,
    onScrub: React.PropTypes.func,
  },

  handleClick: function(name) {
    this.props.onPress(name);
  },

  handleTouchEnd: function(event) {
    this.toggleControlBar();
  },

  handlePress: function(name) {
    Log.verbose("VideoView Handle Press: " + name);
    this.setState({lastPressedTime: new Date().getTime()});
    if (this.state.showControls) {
      if (name === "LIVE") {
        this.props.onScrub(1);
      } else {
        this.props.onPress(name);
      }
    } else {
      this.props.onPress(name);
    }
  },

  _renderDefaultScreen: function(progressBar, controlBar) {
    var endScreenConfig = this.props.config.endScreen || {};
    var replaybuttonLocation = styles.replaybuttonCenter;
    var replaybutton;
    if(endScreenConfig.showReplayButton) {
      var fontFamilyStyle = {fontFamily: this.props.config.icons.replay.fontFamilyName};
      replaybutton = (
        <TouchableHighlight 
          accessible={true} accessibilityLabel={BUTTON_NAMES.REPLAY} accessibilityComponentType="button"
          onPress={(name) => this.handleClick("PlayPause")}
          underlayColor="transparent"
          activeOpacity={0.5}>
          <Text style={[styles.replaybutton, fontFamilyStyle]}>{this.props.config.icons.replay.fontString}</Text>
        </TouchableHighlight>
      );
    }

    var title = endScreenConfig.showTitle ? this.props.title : null;
    var description = endScreenConfig.showDescription ? this.props.description : null;
    var infoPanel =
      (<InfoPanel title={title} description={description} />);

    return (
      <View
        style={styles.fullscreenContainer}>
        <Image
        source={{uri: this.props.promoUrl}}
        style={[styles.fullscreenContainer,{position:"absolute", top:0, left:0, width:this.props.width, height: this.props.height}]}
        resizeMode={Image.resizeMode.contain}>
        </Image>
        {infoPanel}
        <View style={replaybuttonLocation}>
          {replaybutton}
        </View>
        <View style={styles.controlBarPosition}>
          {this._renderBottomOverlay(true)}
        </View>
      </View>
    );
  },

  handleScrub: function(value) {
    this.props.onScrub(value);
  },

  _renderBottomOverlay: function(show) {
    var shouldShowClosedCaptionsButton =
      this.props.availableClosedCaptionsLanguages &&
      this.props.availableClosedCaptionsLanguages.length > 0;
      Log.log("duration: " +this.props.duration)
    return (<BottomOverlay
      width={this.props.width}
      height={this.props.height}
      primaryButton={"replay"}
      playhead={this.props.duration}
      duration={this.props.duration}
      platform={this.props.platform}
      volume={this.props.volume}
      onPress={(name) => this.handlePress(name)}
      shouldShowProgressBar={true}
      showWatermark={this.props.showWatermark}
      handleControlsTouch={() => this.props.handleControlsTouch()}
      onScrub={(value)=>this.handleScrub(value)}
      fullscreen={this.props.fullscreen}
      isShow={show}
      config={{
        controlBar: this.props.config.controlBar,
        buttons: this.props.config.buttons,
        icons: this.props.config.icons,
        live: this.props.config.live,
        general: this.props.config.general
      }} />);
  },

  render: function() {
      return this._renderDefaultScreen();
  }
});

module.exports = EndScreen;
