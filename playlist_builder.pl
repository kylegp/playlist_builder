#!/usr/bin/perl -w

#use strict;
use Env;
use Gtk2 '-init';
use MP3::Tag;

# Set up boolean values
use constant TRUE => 1;
use constant FALSE => 0;

my $text_list = "";
my $user_input;

# Window creation and management
my $window = Gtk2::Window->new;
$window->set_title('Playlist Creator');
$window->set_default_size(800,450);
$window->set_border_width(10);
$window->signal_connect(destroy => sub{ Gtk2->main_quit });

# VBox and HBox creation
my $top_vbox    = Gtk2::VBox->new(FALSE,2);
my $list_vbox   = Gtk2::VBox->new(FALSE,2);
my $button_hbox = Gtk2::HBox->new(FALSE,2);

# Buttons
my $add_button   = Gtk2::Button->new("_Add Files");
my $build_button = Gtk2::Button->new("_Build");
my $quit_button  = Gtk2::Button->new("_Close");

my $frame=Gtk2::Frame->new('File List');
my $song_buffer=Gtk2::TextBuffer->new();
my $song_view=Gtk2::TextView->new_with_buffer($song_buffer);
$song_view->set_editable(FALSE);

$window->add($top_vbox);
$top_vbox->pack_start($list_vbox,TRUE,TRUE,5); 
$top_vbox->pack_start($button_hbox,FALSE,FALSE,5); 
$frame->add($song_view);
$list_vbox->pack_start($frame, TRUE, TRUE,5);

# Button events
$add_button->signal_connect(clicked => \&add_files );
$build_button->signal_connect(clicked => \&build_list );
$quit_button->signal_connect(clicked => \&close_window );

# Packing buttons
#   The buttons are packed from the right side
#   Parameters: <item to add>,<expand>,<fill>,<padding>
$button_hbox->pack_end($quit_button,0,0,5);
$button_hbox->pack_end($build_button,0,0,5);
$button_hbox->pack_end($add_button,0,0,5);

$window->show_all;
Gtk2->main;

#### Subroutines ####
sub add_files {
   my @filename;
   # If this is the start of new playlist, prompt for playlist name
   if (not defined $user_input) { &playlist_name_dialog() }

   # File selection popup. Allows multiple file selection.
   my $file_selector=Gtk2::FileChooserDialog->new("add",$window,"open",'gtk-cancel'=>'cancel','gtk-ok'=>'ok');
   $file_selector->set_select_multiple(TRUE);
   $file_selector->set_current_folder("/home/$ENV{'USER'}/Music");
   if ('ok' eq $file_selector->run) { @filename = $file_selector->get_filenames }

   $file_selector->destroy;

   # If files have been added, add each to the song_buffer list
   if (scalar(@filename)) {
      foreach (@filename) { $text_list.=$_."\n" }
      $song_buffer->set_text("$text_list\n");
   }
   return;
}

sub build_list {
   my (@temptext, @temp);
   my %tag_info;

   (my $start, my $end) = $song_buffer->get_bounds;
   @temptext = split("\n", $song_buffer->get_text($start, $end, TRUE));

   # Get tag info for each file
   foreach (@temptext){
      $tag_info{$_."_tag"} = MP3::Tag->new($_) or die "No tag available for $_\n";
      $tag_info{$_."_tag"}->get_tags();
      if (exists $tag_info{$_."_tag"}->{ID3v1}) {
         $tag_info{$_."_title"} = $tag_info{$_."_tag"}->{ID3v1}->title;
         $tag_info{$_."_artist"} = $tag_info{$_."_tag"}->{ID3v1}->artist;
         $tag_info{$_."_time"} = $tag_info{$_."_tag"}->total_secs();
#      } elsif (exists $tag_info{$_."_tag"}->{ID3v2}){
#         $tag_info{$_."_title"} = $tag_info{$_."_tag"}->{ID3v2}->get_frame(TIT2);
#         $tag_info{$_."_length"} = $tag_info{$_."_tag"}->{ID3v2}->get_frame(TLEN);
#         $tag_info{$_."_time"} = $tag_info{$_."_tag"}->total_secs();
#      }
	  } else {
         die "No ID3 tag for $_\n";
      }
      $tag_info{$_."_tag"}->close();
   }

   open PLAYLIST, ">", "$user_input.m3u" or die "Could not create/open $user_input.m3u\n";
   print PLAYLIST "\#EXTM3U\n\n";   # Write necesary m3u first line
   foreach (@temptext) {
      print PLAYLIST "\#EXTINT - $tag_info{$_.'_time'},$tag_info{$_.'_artist'} - $tag_info{$_.'_title'}\n";
      push(@temp, s#^\/home\/$ENV{'USER'}\/Music#\.\.\/MUSIC#g);
      print PLAYLIST "$_\n";
   }
   close PLAYLIST;
}

sub playlist_name_dialog {
   # Create dialog window and entry widget
   my $dialog = Gtk2::Dialog->new('New Playlist Name',undef,[qw/modal destroy-with-parent/],'gtk-ok'=>'ok');
   my $input_vbox = $dialog->vbox;
   my $entry_box = Gtk2::Entry->new();

   # Dialog window and entry widget parameters
   $dialog->set_response_sensitive('ok',FALSE);
   $dialog->set_default_size(500,75);
   $entry_box->set_has_frame(TRUE);
   $entry_box->set_editable(TRUE);
   $input_vbox->set_border_width(5);

   # Once there is entry in txt box, allow Ok button
   $entry_box->signal_connect(changed=>sub{$dialog->set_response_sensitive('ok',TRUE)});

   $input_vbox->pack_start($entry_box,TRUE,TRUE,5);
   $input_vbox->show_all;

   if ('ok' eq $dialog->run) {
      $user_input = $entry_box->get_text;
      $frame->set_label("File List - $user_input");
      $dialog->destroy;
   }
}

sub check_file_existance (@file_list){
   foreach (@file_list) {
      if (! -e) {
      }
   }
}

sub close_window {
   Gtk2->main_quit;
}

