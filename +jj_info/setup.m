function opts = setup()

% - STATES - %
STATES.sequence = { 'fixation', 'display_random_vs_info_cues' ...
  , 'look_to_random_vs_info', 'display_info_cues' };

% - SCREEN + WINDOW - %
SCREEN.index = 0;
SCREEN.background_color = [ 0 0 0 ];
[windex, wrect] = Screen( 'OpenWindow', SCREEN.index, SCREEN.background_color, [], 32 );

WINDOW.center = round( [mean(wrect([1 3])), mean(wrect([2 4]))] );
WINDOW.index = windex;
WINDOW.rect = wrect;

% - IO - %
IO.edf_file = 'txst.edf';
IO.edf_folder = '~/Desktop';

% - EYE TRACKER - %
TRACKER = EyeTracker( IO.edf_file, IO.edf_folder, WINDOW.index );
TRACKER.bypass = true;

% - TIMINGS - %
time_in.task = Inf;
time_in.fixation = Inf;
time_in.display_random_vs_info_cues = 0;
time_in.look_to_random_vs_info = 10;
time_in.display_info_cues = 2;
time_in.reward = 0;

fixations.fix_square = 2;
fixations.receive_info_cue = 1;
fixations.receive_random_cue = 1;
fixations.make_choice = 1;

% - TIMERS - %
TIMER = Timer();
fs = fieldnames( time_in );
for i = 1:numel(fs)
  TIMER.add_timer( fs{i}, time_in.(fs{i}) );
end

% - STIMULI - %
fix_square = Rectangle( WINDOW.index, WINDOW.rect, [200, 200] );
fix_square.color = [ 100, 50, 30 ];
fix_square.put( 'center' );
fix_square.make_target( TRACKER, fixations.fix_square );
fix_square.blink( .5 );

receive_info_cue = Rectangle( WINDOW.index, WINDOW.rect, [200, 200] );
receive_info_cue.color = [ 100, 20, 50 ];
receive_info_cue.put( 'center' );
receive_info_cue.make_target( TRACKER, fixations.receive_info_cue );

receive_random_cue = Rectangle( WINDOW.index, WINDOW.rect, [200, 200] );
receive_random_cue.color = [ 200, 200, 40 ];
receive_random_cue.put( 'center' );
receive_random_cue.make_target( TRACKER, fixations.receive_random_cue );

info_cue1 = Rectangle( WINDOW.index, WINDOW.rect, [200, 200] );
info_cue1.color = [ 200, 200, 10 ];
info_cue1.put( 'center-left' );

info_cue2 = Rectangle( WINDOW.index, WINDOW.rect, [200, 200] );
info_cue2.color = [ 200, 30, 10 ];
info_cue2.put( 'center-left' );

random_cue1 = Rectangle( WINDOW.index, WINDOW.rect, [200, 200] );
random_cue1.color = [ 200, 30, 40 ];
random_cue1.put( 'center-right' );

random_cue2 = Rectangle( WINDOW.index, WINDOW.rect, [200, 200] );
random_cue2.color = [ 20, 50, 100 ];
random_cue2.put( 'center-right' );

STIMULI.fix_square = fix_square;
STIMULI.receive_info_cue = receive_info_cue;
STIMULI.receive_random_cue = receive_random_cue;
STIMULI.info_cue1 = info_cue1;
STIMULI.info_cue2 = info_cue2;
STIMULI.random_cue1 = random_cue1;
STIMULI.random_cue2 = random_cue2;

% - REWARDS - %
REWARDS.info_cue1 = 100;
REWARDS.info_cue2 = 300;
REWARDS.random = [ 100, 300 ];

% - STORE - %
opts.STATES = STATES;
opts.SCREEN = SCREEN;
opts.WINDOW = WINDOW;
opts.IO = IO;
opts.TRACKER = TRACKER;
opts.TIMER = TIMER;
opts.STIMULI = STIMULI;
opts.REWARDS = REWARDS;

end