#!/usr/bin/perl
use warnings;
use strict;

#-----------------
# Configurable Default Options
#-----------------

my $rootDirectory = $ENV{"HOME"};
my $inputDirectory = '$rootDirectory/Videos';                                                          #/home/public/Videos/TV/Sonarr
my $outputDirectory = '';                                                                              #/home/public/Videos/TV/Sonarr
my $tmpDirectory = '/tmp';
my $logLevel = 'ALL';
my $logFile = '$rootDirectory/encoding.results';
my $dryRun = 0;
my $forceRun = 0;
my $metadataRun = 0;
my $deleteMetadata = 0;
my $pidLocation = '$rootDirectory/plex-encoding.pid';
my $threadCount = 4;                                                                                   # 0 is unlimited
my $audioStereoCodec = 'aac';
my $audioSurroundCodec = 'ac3';
my $audioUpdateMethod = 'convert';                                                                     # convert, export, delete
my $audioImportExtension = '.mp3,.aac,.ac3,.flac,.wav';                                                # comma list of audio extensions
my $audioExportExtension = '.${stream}.${title}.${disposition}.${language}';
my $deleteInputFiles = 0;
my $fileIgnoreRegex = '.*\\/(Downloads?|Uploads?|Imports?|To Import|Music)\\/.*';
my $videoCodec = 'libx265';                                                                            # libx264, libx265
my $videoUpdateMethod = 'convert';                                                                     # convert, export, delete
my $videoPreset = 'none';                                                                              # ultrafast, superfast, veryfast, fast, medium, slow, slower, veryslow, placebo, none
my $videoProfile = 'high';                                                                             # For x264 baseline, main, high | For x265 main, high
my $videoPixelFormat = 'yuv420p,yuv420p10le';
my $videoPixelFormatExclusionOrder = 'depth,channel,compression,bit,format';
my $videoPixelFormatPreferenceOrder = 'depth,channel,compression,bit,format';
my $videoQuality = 23;                                                                                 # 1-50, lower is better quailty
my $videoLevel = '4.1';                                                                                # 1.0 to 6.1
my $videoFrameRate = 'copy';                                                                           # Any Fraction, copy, NTSC (29.97), PAL (25), FILM (24), NTSC_FILM (23.97)
my $videoTune = 'fastdecode';                                                                          # animation, fastdecode, film, grain, stillimage, zerolatency
my $videoExportExtension = '.${stream}.${title}.${disposition}.${language}';
my $subtitlesUpdateMethod = 'export';                                                                  # convert, export, delete
my $subtitleCodec = 'srt,aac,pgs';                                                                     # Comma list of allowed formats
my $subtitleImportExtension = '.srt,.aac';                                                             # Comma list of subtitle extensions
my $subtitleExportExtension = '.${stream}.${title}.${disposition}.${language}';
my $bitratePerAudioChannel = 65536;                                                                    # 65536 is default
my $videoOutputExtension = '.mkv';
my $sortBy = 'size';                                                                                   # date, name, size, reverse-date, reverse-name, reverse-size

#-----------------
# Non-Configurable Variables
#-----------------

my $path = $0;
my $command = $ARGV[0];
my @passedParameters = ();
my @additionalParameters = ();
my $logLevelValue=0;
my $dispositionList='default,dub,original,comment,lyrics,karaoke,forced,hearing_impaired,visual_impaired,clean_effects,attached_pic,captions,descriptions,dependent,metadata';
my $metadataTitle='title';
my $metadataLanguage='language';
my $metadataCodecName='ENCODER-CODEC';
my $metadataAudioBitRate='ENCODER-BIT-RATE';
my $metadataVideoLevel='ENCODER-LEVEL';
my $metadataVideoPixelFormat='ENCODER-PIXEL-FORMAT';
my $metadataVideoFrameRate='ENCODER-FRAME-RATE';
my $metadataVideoPreset='ENCODER-PRESET';
my $metadataVideoProfile='ENCODER-PROFILE';
my $metadataVideoQuality='ENCODER-QUALITY';
my $metadataVideoTune='ENCODER-TUNE';
my $lockfileExtension='.compression.lock.pid';
my $allPixelFormats=`ffmpeg -pix_fmts -loglevel error`;

#-----------------
# Input Value Handling
#-----------------
sub analyzeCommands {
    for(my $i = 1; $i < @ARGV; $i++) {
        my $arg = lc $ARGV[$i];
        my $val = $ARGV[$i + 1];
        if ($arg eq '--audio') {
            $audioStereoCodec = $val;
            $audioSurroundCodec = $val;
            $i++;
        } elsif ($arg eq '--audio-bitrate') {
            $bitratePerAudioChannel = $val;
            $i++;
        } elsif ($arg eq '--audio-export-extension') {
            $audioExportExtension = $val;
            $i++;
        } elsif ($arg eq '--audio-import-extension') {
            $audioImportExtension = $val;
            $i++;
        } elsif ($arg eq '--audio-stereo') {
            $audioStereoCodec = $val;
            $i++;
        } elsif ($arg eq '--audio-surround') {
            $audioSurroundCodec = $val;
            $i++;
        } elsif ($arg eq '--audio-update') {
            $audioUpdateMethod = $val;
            $i++;
        } elsif ($arg eq '--delete-input') {
            $deleteInputFiles = 1;
        } elsif ($arg eq '--delete-metadata') {
            $deleteMetadata = 1;
        } elsif ($arg eq '--dry') {
            $dryRun = 1;
        } elsif ($arg eq '--ext') {
            $videoOutputExtension = $val;
            $i++;
        } elsif ($arg eq '--force') {
            $forceRun = 1;
        } elsif ($arg eq '--ignore') {
            $fileIgnoreRegex = $val;
            $i++;
        } elsif ($arg eq '--input') {
            $inputDirectory = $val;
            $i++;
        } elsif ($arg eq '--log') {
            $logFile = $val;
            $i++;
        } elsif ($arg eq '--log-level') {
            $logLevel = uc $val;
            $i++;
        } elsif ($arg eq '--metadata') {
            $metadataRun = 1;
        } elsif ($arg eq '--output') {
            $outputDirectory = $val;
            $i++;
        } elsif ($arg eq '--pid') {
            $pidLocation = $val;
            $i++;
        } elsif ($arg eq '--root') {
            $rootDirectory = $val;
            $i++;
        } elsif ($arg eq '--sort') {
            $sortBy = $val;
            $i++;
        } elsif ($arg eq '--subtitle') {
            $subtitleCodec = $val;
            $i++;
        } elsif ($arg eq '--subtitle-export-extension') {
            $subtitleExportExtension = $val;
            $i++;
        } elsif ($arg eq '--subtitle-import-extension') {
            $subtitleImportExtension = $val;
            $i++;
        } elsif ($arg eq '--subtitle-update') {
            $subtitlesUpdateMethod = $val;
            $i++;
        } elsif ($arg eq '--thread') {
            $threadCount = $val;
            $i++;
        } elsif ($arg eq '--tmp') {
            $tmpDirectory = $val;
            $i++;
        } elsif ($arg eq '--video') {
            $videoCodec = $val;
            $i++;
        } elsif ($arg eq '--video-export-extension') {
            $videoExportExtension = $val;
            $i++;
        } elsif ($arg eq '--video-level') {
            $videoLevel = $val;
            $i++;
        } elsif ($arg eq '--video-pixel') {
            $videoPixelFormat = $val;
            $i++;
        } elsif ($arg eq '--video-pixel-exclusion') {
            $videoPixelFormatExclusionOrder = $val;
            $i++;
        } elsif ($arg eq '--video-pixel-preference') {
            $videoPixelFormatPreferenceOrder = $val;
            $i++;
        } elsif ($arg eq '--video-preset') {
            $videoPreset = $val;
            $i++;
        } elsif ($arg eq '--video-profile') {
            $videoProfile = $val;
            $i++;
        } elsif ($arg eq '--video-quality') {
            $videoQuality = $val;
            $i++;
        } elsif ($arg eq '--video-rate') {
            $videoFrameRate = $val;
            $i++;
        } elsif ($arg eq '--video-tune') {
            $videoTune = $val;
            $i++;
        } elsif ($arg eq '--video-update') {
            $videoUpdateMethod = $val;
            $i++;
        } elsif ($arg eq '--') {
            for($i++; $i < @ARGV; $i++) {
                push(@passedParameters, $ARGV[$i]);
            }
        } else {
            push(@additionalParameters, $val);
        }
    }

    if (rindex($inputDirectory, '$rootDirectory', 0) >= 0) {
        $inputDirectory = $rootDirectory . substr($inputDirectory, length('$rootDirectory'));
    }
    if (rindex($logFile, '$rootDirectory', 0) >= 0) {
        $logFile = $rootDirectory . substr($logFile, length('$rootDirectory'));
    }
    if (rindex($pidLocation, '$rootDirectory', 0) >= 0) {
        $pidLocation = $rootDirectory . substr($pidLocation, length('$rootDirectory'));
    }
    if ($outputDirectory eq $inputDirectory) {
        $outputDirectory = '';
    }

    if ($logLevel eq 'NONE') {
        $logLevelValue = 0;
    } elsif ($logLevel eq 'ERROR') {
        $logLevelValue = 1;
    } elsif ($logLevel eq 'WARN') {
        $logLevelValue = 2;
    } elsif ($logLevel eq 'INFO') {
        $logLevelValue = 3;
    } elsif ($logLevel eq 'DEBUG') {
        $logLevelValue = 4;
    } elsif ($logLevel eq 'TRACE') {
        $logLevelValue = 5;
    } elsif ($logLevel eq 'ALL') {
        $logLevelValue = 6;
    } else {
        $logLevelValue = 6;
    }
}
analyzeCommands();

#-----------------
# Assemble the command which was used to call this class
#-----------------
sub getCommand {
    my ($cmd) = @_;
    my $result = "'${path}' '${cmd}'" .
        " --audio-bitrate '${bitratePerAudioChannel}'".
        " --audio-export-extension '${audioExportExtension}'".
        " --audio-import-extension '${audioImportExtension}'".
        " --audio-stereo '${audioStereoCodec}'" .
        " --audio-surround '${audioSurroundCodec}'" .
        " --audio-update '${audioUpdateMethod}'";
    if ($deleteInputFiles) {
        $result .= ' --delete-input';
    }
    if ($deleteMetadata) {
        $result .= ' --delete-metadata';
    }
    if ($dryRun) {
        $result .= ' --dry';
    }
    $result .= " --ext '${videoOutputExtension}'";
    if ($forceRun) {
        $result .= ' --force';
    }
    $result .= " --ignore '${fileIgnoreRegex}'" .
        " --input '${inputDirectory}'" .
        " --log '${logFile}'" .
        " --log-level '${logLevel}'";
    if ($metadataRun) {
        $result .= ' --metadata'
    }
    $result .= " --output '${outputDirectory}'" .
        " --pid '${pidLocation}'" .
        " --sort '${sortBy}'" .
        " --subtitle '${subtitleCodec}'" .
        " --subtitle-export-extension '${subtitleExportExtension}'" .
        " --subtitle-import-extension '${subtitleImportExtension}'" .
        " --subtitle-update '${subtitlesUpdateMethod}'" .
        " --thread '${threadCount}'" .
        " --tmp '${tmpDirectory}'" .
        " --video '${videoCodec}'" .
        " --video-export-extension '${videoExportExtension}'" .
        " --video-level '${videoLevel}'" .
        " --video-pixel '${videoPixelFormat}'" .
        " --video-pixel-exclusion '${videoPixelFormatExclusionOrder}'" .
        " --video-pixel-preference '${videoPixelFormatPreferenceOrder}'" .
        " --video-preset '${videoPreset}'" .
        " --video-profile '${videoProfile}'" .
        " --video-quality '${videoQuality}'" .
        " --video-rate '${videoFrameRate}'" .
        " --video-tune '${videoTune}'" .
        " --video-update '${videoUpdateMethod}'";
    if (@additionalParameters) {
        $result .= " '" . join("' '", @additionalParameters) . "'";
    }
    if (@passedParameters) {
        $result .= " -- '" . join("' '", @passedParameters) . "'";
    }
    return $result;
}

#-----------------
# Handle error case
#-----------------
sub getUsage {
    return "Usage $path [active|start|start-local|output-[error|warn|info|debug|trace|all]|stop]" .
        ' [--audio List of allowed audio codecs, updates both stereo and surround {aac,mp3}}]' .
        ' [--audio-bitrate Bit rate per an audio channel {98304}]' .
        ' [--audio-export-extension Audio extension to export to when run in export mode {.audio}]' .
        ' [--audio-import-extension List of audio extensions to read {.mp3,.acc,.ac3}]' .
        ' [--audio-stereo List of allowed audio codecs {aac,mp3}}]' .
        ' [--audio-surround List of allowed audio codecs {aac,mp3}}]' .
        ' [--audio-update Method to use for updating audio {convert|export|delete}]' .
        ' [--delete-input Will delete input files after convert. Note video file always deletes if input and output are the same location]' .
        ' [--delete-metadata Will remove old metadata from the files]' .
        ' [--dry Will output what commands it will execute without modifying anything]' .
        ' [--ext The extension of the output file {copy|.mp4|.mkv}]' .
        ' [--force Will always convert, even if codecs matches]' .
        ' [--ignore Regex match of file names with directory to ignore {.*/(Downloads?|Uploads?|Imports?|To Import|Music)/.*}]' .
        ' [--input Directory of files to process {~/Video}]' .
        ' [--output Output directory of the processed files, blank will cause replacement {~/ProcessedVideo}]' .
        ' [--log Location of where to output the logs {~/encoding.results}]' .
        ' [--log-level The level which to log {ALL|TRACE|DEBUG|INFO|WARN|ERROR|NONE}]' .
        ' [--metadata Will always update files in order to update metadata]' .
        ' [--pid Location of pid file {~/plex-encoding.pid}]' .
        ' [--root Location of root directory {~}]' .
        ' [--sort What order to process the files in {date|size|reverse-date|reverse-size}]' .
        ' [--subtitle List of allowed subtitle codecs {srt,ass}]' .
        ' [--subtitle-export-extension Subtitle extension to export to when run in export mode {.subtitles}]' .
        ' [--subtitle-import-extension List of subtitle extensions to read {.srt,.ass}]' .
        ' [--subtitle-update Method to use for updating subtitles {convert|export|delete}]' .
        ' [--thread Thread to use while processing {3}]' .
        ' [--tmp tmpDirectory Temporary directory to store processing video files {/tmp}]' .
        ' [--video videoCodec List of allowed video codecs {libx264,libx265}]' .
        ' [--video-export-extension Video extension to export to when run in export mode {.video}]' .
        ' [--video-level Maximum Allowed Video Level {4.1}]' .
        ' [--video-pixel List of allowed pixel formats {yuv420p,yuv420p10le}]' .
        ' [--video-pixel-exclusion videoPixelFormatExclusionOrder {depth,channel,compression,bit,format}]' .
        ' [--video-pixel-preference videoPixelFormatPreferenceOrder {depth,channel,compression,bit,format}]' .
        ' [--video-preset The preset to use when processing the video {ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo}]' .
        ' [--video-profile The profile to use when processing the video {baseline|main|high}]' .
        ' [--video-quality The quality to use when processing the video {1-50}]' .
        ' [--video-rate The frame rate to use when processing the file {any_faction|ntsc|ntsc_film|pal|film}]' .
        ' [--video-tune The tune parameter to use when processing the file {animation|fastdecode|film|grain|stillimage|zerolatency}]' .
        ' [--video-update Method to use for updating video {convert|export|delete}]';
}
if (!$command) {
    die getUsage();
}

#-----------------
# Logging
#-----------------

sub error {
    if ($logLevelValue >= 1) {
        writeLog('[ERROR] ' . join(' ', @_));
    }
}

sub warning {
    if ($logLevelValue >= 2) {
        writeLog('[WARN] ' . join(' ', @_));
    }
}

sub info {
    if ($logLevelValue >= 3) {
        writeLog('[INFO] ' . join(' ', @_));
    }
}

sub debug {
    if ($logLevelValue >= 4) {
        writeLog('[DEBUG] ' . join(' ', @_));
    }
}

sub trace {
    if ($logLevelValue >= 5) {
        writeLog('[TRACE] ' . join(' ', @_));
    }
}

if ($logFile) {
    if (-f $logFile) {
        open(LOGFILE, '>>', $logFile) or die ("Unable to open log file '$logFile': $!");
    } else {
        open(LOGFILE, '>', $logFile) or die ("Unable to open log file '$logFile': $!");
    }
}
sub writeLog {
    if ($logFile) {
        print LOGFILE '[' . getTime() . ']' . join(' ', @_) . "\n";
    } else {
        print '[' . getTime() . ']' . join(' ', @_) . "\n";
    }
}

sub getTime {
  my ($second,$minute,$hour,$day,$month,$year) = gmtime();
  return sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $year + 1900, $month + 1, $day, $hour, $minute, $second)
}