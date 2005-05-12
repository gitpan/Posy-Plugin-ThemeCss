package Posy::Plugin::ThemeCss;
use strict;

=head1 NAME

Posy::Plugin::ThemeCss - Posy plugin for Cascading Style Sheet themes.

=head1 VERSION

This describes version B<0.42> of Posy::Plugin::ThemeCss.

=cut

our $VERSION = '0.42';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::TextTemplate
	Posy::Plugin::YamlConfig
	Posy::Plugin::ThemeCss));
    @actions = qw(init_params
	    ...
	    head_template
	    theme_css_set
	    head_render
	    ...
	);

=head1 DESCRIPTION

This plugin allows a visitor to choose which CSS layout they would like
to use when browsing your site, by checking a CGI parameter.

There are two variables filled in by this plugin that can be used within
your flavour files.  The $flow_theme_css_display variable contains the
stylesheet link metatag for the currently selected CSS file.  This
variable must be inserted into your head flavour file.

The second variable is $flow_theme_css_links which presents a list
of all the different CSS themes available on your site.

If you don't want to use the $flow_theme_css_links list for accessing your
various CSS themes, you can simply tack on the following CGI string to a URL:

B<?theme_css=theme_name>: where 'theme_name' is the name of the CSS theme.

=head2 Activation

This plugin needs to be added to both the plugins list and the actions
list.  It doesn't really matter where it is in the plugins list,
just so long as you also have the Posy::Plugin::YamlConfig plugin
as well.

In the actions list, it needs to go somewhere after B<head_template>
and before B<head_render>, since the config needs to have been read,
and this needs to set values before the head is rendered.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the data directory.

This requires the Posy::Plugin::YamlConfig plugin (or equivalent), because the
configuration variables for this plugin are not simple string values; it
expects most of the config values to be in a hash at
$self->{config}->{theme_css}

There are two main config settings;

=over 

=item B<theme_css_default>

The default CSS selection when none is specified.
This is a separate value because one might want to use
a different default theme in a different part of the site,
so this enables one to just set this value without having
to set the others again.

=item B<theme_css>

A hash containing the rest of the settings.

=over

=item B<themes>

This list defined the order of the labels that are shown in the
list of CSS themes set in $flow_theme_css_links
Note that for every entry in this list, there must be a corresponding
entry in the files hash.

=item B<files>

These are the (CSS) files associated with the CSS selections.

=item B<param>

The name of the parameter to check for selecting CSS themes.
(default: theme_css)

=back

=back

Example config file:

	---
	theme_css_default: Smooth
	theme_css:
	  themes:
	    - Smooth
	    - Smooth2
	    - Midnight
	    - Blue2
	    - Dark
	    - Gold
	  files:
	    Smooth: '/styles/theme_default.css'
	    Smooth2: '/styles/theme_alt.css'
	    Midnight: '/styles/theme_midblu.css'
	    Blue2: '/styles/theme_blue2.css'
	    Dark: '/styles/theme_dark.css'
	    Gold: '/styles/theme_gold.css'
	  param: theme_css

=cut

=head1 OBJECT METHODS

Documentation for developers and those wishing to write plugins.

=head2 init

Do some initialization; make sure that default config values are set.

=cut
sub init {
    my $self = shift;
    $self->SUPER::init();

    # set defaults
    $self->{config}->{theme_css}->{param} = 'theme_css'
	if (!defined $self->{config}->{theme_css}->{param});
} # init

=head1 Flow Action Methods

Methods implementing actions.

=head2 theme_css_set

$self->theme_css_set($flow_state)

Sets $flow_state->{theme_css_display} and $flow_state->{theme_css_links}
(aka $flow_theme_css_display and $flow_theme_css_links)
to be used inside flavour files.

=cut
sub theme_css_set {
    my $self = shift;
    my $flow_state = shift;

    my $css_param = $self->param($self->{config}->{theme_css}->{param});
    my $theme_name;
    my $css_file;
    my $cookie;

    $theme_name = ($css_param) ? $css_param
	: $self->{config}->{theme_css_default};

    $theme_name = $self->{config}->{theme_css_default}
	if (not $self->{config}->{theme_css}->{files}->{$theme_name});
    $css_file = $self->{config}->{theme_css}->{files}->{$theme_name};

    my $display = qq{<link rel="stylesheet" href="$css_file" title="default" type="text/css" />};
    my $links = $self->theme_css_links($theme_name);

    $flow_state->{theme_css_links} = $links;
    $flow_state->{theme_css_display} = $display;

    1;
} # theme_css_set

=head1 Helper Methods

Methods which can be called from within other methods.

=head2 theme_css_links

$links = $self->theme_css_links($theme_name);

Generates the list of all CSS theme links.
The $theme_name variable is the name of the currently active theme.

=cut
sub theme_css_links {
    my $self = shift;
    my $theme_name = shift;

    my $links  = qq{<ul class="theme_css_links">\n};

    my $active = qq{<li class="theme_css_links_active_item">};
    my $item   = qq{<li class="theme_css_links_item">};
    my $url = $self->{url};
    my $path_info = $self->{path}->{info};
    $path_info =~ s#^/##;
    my $param_name = $self->{config}->{theme_css}->{param};
    my $anchor = qq{<a href="$url/$path_info};
    my $end    = qq{</a></li>\n};

    foreach (@{$self->{config}->{theme_css}->{themes}})
    {
        $links .= (/^$theme_name$/) ? qq{$active$anchor?$param_name=$_">$_$end}
                                  : qq{$item$anchor?$param_name=$_">$_$end};
    }

    $links .= qq{</ul>\n};

    return $links;
} # theme_css_links

=head1 INSTALLATION

Installation needs will vary depending on the particular setup a person
has.

=head2 Administrator, Automatic

If you are the administrator of the system, then the dead simple method of
installing the modules is to use the CPAN or CPANPLUS system.

    cpanp -i Posy::Plugin::ThemeCss

This will install this plugin in the usual places where modules get
installed when one is using CPAN(PLUS).

=head2 Administrator, By Hand

If you are the administrator of the system, but don't wish to use the
CPAN(PLUS) method, then this is for you.  Take the *.tar.gz file
and untar it in a suitable directory.

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

=head2 User With Shell Access

If you are a user on a system, and don't have root/administrator access,
you need to install Posy somewhere other than the default place (since you
don't have access to it).  However, if you have shell access to the system,
then you can install it in your home directory.

Say your home directory is "/home/fred", and you want to install the
modules into a subdirectory called "perl".

Download the *.tar.gz file and untar it in a suitable directory.

    perl Build.PL --install_base /home/fred/perl
    ./Build
    ./Build test
    ./Build install

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the scripts (posy_one,
posy_static).

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 REQUIRES

    Posy
    Posy::Core
    Posy::Plugin::TextTemplate
    Posy::Plugin::YamlConfig

    Test::More

=head1 SEE ALSO

perl(1).
Posy

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004-2005 by Kathryn Andersen

Based in part on the 'css' blosxom plugin by
Eric Davis <edavis <at> foobargeek <dot> com> http://www.foobargeek.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::ThemeCss
__END__
