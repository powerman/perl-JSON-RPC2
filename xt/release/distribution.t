use Test::More;

eval { require Test::Distribution };
plan( skip_all => 'Test::Distribution not installed' ) if $@;
Test::Distribution->import(
   podcoveropts => {
#        also_private    => [
#            qr/^(?:IMPORT)$/,
#        ],
#        pod_from        => 'MAIN PM FILE HERE',
   }
);
