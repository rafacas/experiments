package listener;
use Dancer2 ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

true;
