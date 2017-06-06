function opts = setup()

% - STATES - %
STATES.sequence = { 'new_trial', 'fixation', 'display_random_vs_info_cues' ...
  , 'look_to_random_vs_info', 'display_info_cues', 'reward', 'iti' ...
  , 'display_social_image' };

% - IO - %
% IO.repo_folder = 'C:\Repositories';
IO.repo_folder = 'C:\Users\changLab\Repositories';
IO.edf_file = '06_06TaB';
IO.data_file = '06_06TaB.mat';
IO.edf_folder = fullfile( IO.repo_folder, 'jj_info', 'data' );
IO.data_folder = fullfile( IO.repo_folder, 'jj_info', 'data' );
IO.stimuli_path = fullfile( IO.repo_folder, 'jj_info', 'stimuli' );

addpath( genpath(fullfile(IO.repo_folder, 'ptb_helpers')) );
addpath( fullfile(IO.repo_folder, 'serial_comm') );

jj_info.util.assert__is_valid_path( IO.data_folder );
% assert__file_does_not_exist( fullfile(IO.data_folder, IO.data_file) );
% assert__file_does_not_exist( fullfile(IO.edf_folder, IO.edf_file) );

% - META - %
META.monkey = 'Tarantino';
META.date = '06/06/17';
META.session = '2';
META.notes = ' 500 choice, 100 initial fix';

% - INTERFACE - %
INTERFACE.use_eyelink = false;
INTERFACE.use_arduino = false;

IS_JUICE = false;

% - SCREEN + WINDOW - %
SCREEN = ScreenManager();
WINDOW = SCREEN.open_window( 0, [0 0 0] );

% - SERIAL - %
port = 'COM4';
messages = struct( 'message', 'clock_synch', 'char', 'C' );
reward_chars = { 'A' };
serial_manager = serial_comm.SerialManager( port, messages, reward_chars );
if ( INTERFACE.use_arduino )
  serial_manager.start();
end

SERIAL.serial_manager = serial_manager;

% - EYE TRACKER - %
TRACKER = EyeTracker( IO.edf_file, IO.edf_folder, WINDOW.index );
TRACKER.bypass = ~INTERFACE.use_eyelink;
TRACKER.init();

if ( IS_JUICE )
  reward_types = { 'big', 'small' };
else
  reward_types = { 'threat', 'neutral' };
end

% - STRUCTURE - %
choice_combs = jj_info.util.allcomb( { ...
    { 'choice' } ...
  , reward_types ...
  , { 'rand1', 'rand2' } ...
  , { {'center-left', 'center-right'}, {'center-right', 'center-left'} }
} );
info_combs = jj_info.util.allcomb( { ...
    { 'info' } ...
  , reward_types ...
  , { 'rand1' } ...
  , { 'center-left', 'center-right' } ...
} );
rand_combs = jj_info.util.allcomb( { ...
    { 'random' } ...
  , reward_types ...
  , { 'rand1', 'rand2' } ...
  , { 'center-left', 'center-right' } ...
} );

bs = [ choice_combs; info_combs; info_combs; rand_combs ];
bs_ids = arrayfun( @(x) {x}, 1:size(bs, 1) );
bs(:, end+1) = bs_ids(:);

STRUCTURE.block_sequence = bs;
STRUCTURE.IS_JUICE = IS_JUICE;

% - TIMINGS - %
time_in.task = Inf;
time_in.trial = Inf;
time_in.new_trial = 0;
time_in.fixation = Inf;
time_in.display_random_vs_info_cues = 0;
time_in.look_to_random_vs_info = 0.5; %2
time_in.display_info_cues = 2;
time_in.display_social_image = 2;
time_in.reward = 0;
time_in.iti = 1;
time_in.error = 3;

fixations.fix_square = .1; %go to .8 for real task
fixations.receive_info_cue = .05; %go to 1 for real task
fixations.receive_random_cue = .05; %go to 1 for real task
fixations.make_choice = .05; %go to 1 for real task

% - TIMERS - %
TIMER = Timer();
TIMER.register( time_in );

% - STIMULI - %
if ( IS_JUICE )
  images.info.big = get_images( fullfile(IO.stimuli_path, 'information', 'big') );
  images.info.small = get_images( fullfile(IO.stimuli_path, 'information', 'small') );
else
  images.info.neutral = get_images( fullfile(IO.stimuli_path, 'information', 'big') );
  images.info.threat = get_images( fullfile(IO.stimuli_path, 'information', 'small') );
end
images.random.rand1 = get_images( fullfile(IO.stimuli_path, 'random', 'rand1') );
images.random.rand2 = get_images( fullfile(IO.stimuli_path, 'random', 'rand2') );
images.social.neutral = get_images( fullfile(IO.stimuli_path, 'social_images', 'neutral') );
images.social.threat = get_images( fullfile(IO.stimuli_path, 'social_images', 'threat') );

sounds.error = get_sounds( fullfile(IO.stimuli_path, 'sounds', 'error') );
sounds.reward = get_sounds( fullfile(IO.stimuli_path, 'sounds', 'reward') );

fix_square = WINDOW.Rectangle( [200, 200] );
fix_square.color = [ 255, 255, 255 ];
fix_square.put( 'center' );
fix_square.make_target( TRACKER, fixations.fix_square );
fix_square.blink( .5 );

receive_info_cue = WINDOW.Rectangle( [350, 350] );
% receive_info_cue.color = [ 42, 172, 227 ];
receive_info_cue.color = [ 247, 148, 30 ];
receive_info_cue.put( 'center' );
receive_info_cue.make_target( TRACKER, fixations.receive_info_cue );

receive_random_cue = WINDOW.Rectangle( [350, 350] );
% receive_random_cue.color = [ 247, 148, 30 ];
receive_random_cue.color = [ 42, 172, 227 ];
receive_random_cue.put( 'center' );
receive_random_cue.make_target( TRACKER, fixations.receive_random_cue );

info_cue = WINDOW.Image( [400, 400], images.info.(reward_types{1}).matrices{1} );
info_cue.color = [ 200, 200, 10 ];
info_cue.put( 'center-left' );

random_cue = WINDOW.Image( [400, 400], images.random.rand1.matrices{1} );
random_cue.color = [ 20, 50, 100 ];
random_cue.put( 'center-right' );

social_image = WINDOW.Image( [400, 400], images.social.neutral.matrices{1} );
social_image.color = [ 20, 50, 100 ];
social_image.put( 'center' );

STIMULI.fix_square = fix_square;
STIMULI.receive_info_cue = receive_info_cue;
STIMULI.receive_random_cue = receive_random_cue;
STIMULI.info_cue = info_cue;
STIMULI.random_cue = random_cue;
STIMULI.social_image = social_image;
STIMULI.images = images;
STIMULI.sounds = sounds;

% - REWARDS - %
REWARDS.social = 300;
REWARDS.big = 600;
REWARDS.small = 50;
REWARDS.random = [ 100, 300 ];

% - STORE - %
opts.STATES = STATES;
opts.STRUCTURE = STRUCTURE;
opts.SCREEN = SCREEN;
opts.WINDOW = WINDOW;
opts.IO = IO;
opts.INTERFACE = INTERFACE;
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