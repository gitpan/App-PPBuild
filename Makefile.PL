use inc::Module::Install;

name            'App-PPBuild';
all_from        'lib/App/PPBuild.pm';
install_script  'bin/ppbuild';
test_requires   'Test::Exception' => '0.27';
requires(
    'YAML::Syck' => '1.05',
    'Exporter' => '5.63',
);

WriteAll;
