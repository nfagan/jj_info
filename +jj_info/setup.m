function opts = setup()

addpath( genpath('C:\Repositories\ptb_helpers') );
addpath( 'C:\Repositories\serial_comm' );

% - STATES - %
STATES.sequence = { 'new_trial', 'fixation', 'display_random_vs_info_cues' ...
  , 'look_to_random_vs_info', 'display_info_cues', 'reward', 'iti' };

% - SCREEN + WINDOW - %
SCREEN = ScreenManager();
WINDOW = SCREEN.open_window( 2, [0 0 0] );

% - IO - %
IO.edf_file = 'txst.edf';
IO.edf_folder = 'C:\Users\Plexon\Desktop';
IO.data_file = 'txst.mat';
IO.data_folder = '~/Desktop';

IO.stimuli_path = 'C:\Repositories\jj_info\stimuli';

jj_info.util.assert__is_valid_path( IO.data_folder );
assert__file_does_not_exist( fullfile(IO.data_folder, IO.data_file) );
assert__file_does_not_exist( fullfile(IO.edf_folder, IO.edf_file) );

% - META - %
META.monkey = '';
META.date = '';
META.session = '';

% - SERIAL - %
port = 'COM4';
messages = struct( 'message', 'clock_synch', 'char', 'C' );
reward_chars = { 'A' };
serial_manager = serial_comm.SerialManager( port, messages, reward_chars );
serial_manager.start();

SERIAL.serial_manager = serial_manager;

% - EYE TRACKER - %
TRACKER = EyeTracker( IO.edf_file, IO.edf_folder, WINDOW.index );
TRACKER.bypass = true;

% - STRUCTURE - %
choice_combs = jj_info.util.allcomb( { ...
    { 'choice' } ...
  , { 'big', 'small' } ...
  , { 'rand1', 'rand2' } ...
  , { {'center-left', 'center-right'}, {'center-right', 'center-left'} }
} );
info_combs = jj_info.util.allcomb( { ...
    { 'info' } ...
  , { 'big', 'small' } ...
  , { 'rand1' } ...
  , { 'center-left', 'center-right' } ...
} );
rand_combs = jj_info.util.allcomb( { ...
    { 'random' } ...
  , { 'big', 'small' } ...
  , { 'rand1', 'rand2' } ...
  , { 'center-left', 'center-right' } ...
} );

STRUCTURE.block_sequence = [ choice_combs; info_combs; info_combs; rand_combs ];

% - TIMINGS - %
time_in.task = Inf;
time_in.trial = Inf;
time_in.new_trial = 0;
time_in.fixation = Inf;
time_in.display_random_vs_info_cues = 0;
time_in.look_to_random_vs_info = 2;
time_in.display_info_cues = 2;
time_in.reward = 0;
time_in.iti = 1;
time_in.error = 3;

fixations.fix_square = .8;
fixations.receive_info_cue = 1;
fixations.receive_random_cue = 1;
fixations.make_choice = 1;

% - TIMERS - %
TIMER = Timer();
TIMER.register( time_in );

% - STIMULI - %
images.info.big = get_images( fullfile(IO.stimuli_path, 'information', 'big') );
images.info.small = get_images( fullfile(IO.stimuli_path, 'information', 'small') );
images.random.rand1 = get_images( fullfile(IO.stimuli_path, 'random', 'rand1') );
images.random.rand2 = get_images( fullfile(IO.stimuli_path, 'random', 'rand2') );

sounds.error = get_sounds( fullfile(IO.stimuli_path, 'sounds', 'error') );
sounds.reward = get_sounds( fullfile(IO.stimuli_path, 'sounds', 'reward') );

fix_square = WINDOW.Rectangle( [200, 200] );
fix_square.color = [ 100, 50, 30 ];
fix_square.put( 'center' );
fix_square.make_target( TRACKER, fixations.fix_square );
fix_square.blink( .5 );

receive_info_cue = WINDOW.Rectangle( [150, 150] );
receive_info_cue.color = [ 42, 172, 227 ];
receive_info_cue.put( 'center' );
receive_info_cue.make_target( TRACKER, fixations.receive_info_cue );

receive_random_cue = WINDOW.Rectangle( [150, 150] );
receive_random_cue.color = [ 247, 148, 30 ];
receive_random_cue.put( 'center' );
receive_random_cue.make_target( TRACKER, fixations.receive_random_cue );

info_cue = WINDOW.Image( [400, 400], images.info.small.matrices{1} );
info_cue.color = [ 200, 200, 10 ];
info_cue.put( 'center-left' );

random_cue = WINDOW.Image( [400, 400], images.random.rand1.matrices{1} );
random_cue.color = [ 20, 50, 100 ];
random_cue.put( 'center-right' );

STIMULI.fix_square = fix_square;
STIMULI.receive_info_cue = receive_info_cue;
STIMULI.receive_random_cue = receive_random_cue;
STIMULI.info_cue = info_cue;
STIMULI.random_cue = random_cue;
STIMULI.images = images;
STIMULI.sounds = sounds;

% - REWARDS - %
REWARDS.big = 600;
REWARDS.small = 50;
REWARDS.random = [ 100, 300 ];

% - STORE - %
opts.STATES = STATES;
opts.STRUCTURE = STRUCTURE;
opts.SCREEN = SCREEN;
opts.WINDOW = WINDOW;
opts.IO = IO;
opts.META = META;
opts.TRACKER = TRACKER;
opts.TIMER = TIMER;
opts.STIMULI = STIMULI;
opts.SERIAL = SERIAL;
opts.REWARDS = REWARDS;

end

function images = get_images(stimuli_path)

imgs = jj_info.util.dirstruct( stimuli_path, '.png' );
imgs = { imgs(:).name };
images.matrices = cellfun( @(x) imread(fullfile(stimuli_path, x)) ...
  , imgs, 'un', false );
images.filenames = imgs;

end

function sounds = get_sounds(stimuli_path)

sound_files = jj_info.util.dirstruct( stimuli_path, '.wav' );
sound_files = { sound_files(:).name };
sounds.matrices = cell( size(sound_files) );
sounds.fs = cell( size(sound_files) );
for i = 1:numel(sound_files)
  [sounds.matrices{i}, sounds.fs{i}] = ...
    audioread( fullfile(stimuli_path, sound_files{i}) );
end
sounds.filenames = sound_files;

end

function assert__file_does_not_exist( file )

assert( exist(file, 'file') ~= 2, 'The file ''%s'' already exists.', file );

end