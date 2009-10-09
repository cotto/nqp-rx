class Regex::P6Regex::Actions;

method TOP($/) {
    my $regex := PAST::Regex.new(
        PAST::Regex.new( :pasttype('scan') ),
        $<nibbler>.ast,
        PAST::Regex.new( :pasttype('pass') ),
        :pasttype('concat')
    );
    my $past := PAST::Block.new( $regex, :blocktype('method') );
    make $past;
}

method nibbler($/) {
    my $past;
    if +$<termish> > 1 {
        $past := PAST::Regex.new( :pasttype('alt') );
        for $<termish> { $past.push($_.ast); }
    }
    else {
        $past := $<termish>[0].ast;
    }
    make $past;
}

method termish($/) {
    my $past := PAST::Regex.new( :pasttype('concat') );
    my $lastlit := 0;
    for $<noun> {
        my $ast := $_.ast;
        if $lastlit && $ast.pasttype eq 'literal' {
            $lastlit[0] := $lastlit[0] ~ $ast[0];
        }
        else {
            $past.push($_.ast);
            $lastlit := $ast.pasttype eq 'literal' ?? $ast !! 0;
        }
    }
    if +$past.list == 1 { $past := $past[0]; }
    make $past;
}

method quantified_atom($/) {
    my $past := $<atom>.ast;
    if $<quantifier> {
       $<quantifier>[0].ast.unshift($past);
       $past := $<quantifier>[0].ast;
    }
    make $past;
}

method atom($/) {
    my $past := $<metachar>
                ?? $<metachar>.ast
                !! PAST::Regex.new( ~$/ , :pasttype('literal') );
    make $past;
}

method quantifier:sym<*>($/) {
    make $<quantmod>.ast;
}

method quantifier:sym<+>($/) {
    my $past := $<quantmod>.ast;
    $past.min(1);
    make $past;
}

method quantifier:sym<?>($/) {
    my $past := $<quantmod>.ast;
    $past.min(0);
    $past.max(1);
    make $past;
}

method quantmod($/) {
    my $past := PAST::Regex.new( :pasttype('quant') );
    my $str := ~$/;
    if    $str eq ':' { $past.backtrack('r'); }
    elsif $str eq ':?' or $str eq '?' { $past.backtrack('f') }
    elsif $str eq ':*' or $str eq '!' { $past.backtrack('g') }
    make $past;
}


method metachar:sym<[ ]>($/) {
    make $<nibbler>.ast;
}

method metachar:sym<.>($/) {
    my $past := PAST::Regex.new( :pasttype('charclass'), :subtype('.') );
    make $past;
}

method metachar:sym<^>($/) {
    my $past := PAST::Regex.new( :pasttype('anchor'), :subtype('bos') );
    make $past;
}

method metachar:sym<^^>($/) {
    my $past := PAST::Regex.new( :pasttype('anchor'), :subtype('bol') );
    make $past;
}

method metachar:sym<$>($/) {
    my $past := PAST::Regex.new( :pasttype('anchor'), :subtype('eos') );
    make $past;
}

method metachar:sym<$$>($/) {
    my $past := PAST::Regex.new( :pasttype('anchor'), :subtype('eol') );
    make $past;
}

method metachar:sym<lwb>($/) {
    my $past := PAST::Regex.new( :pasttype('anchor'), :subtype('lwb') );
    make $past;
}

method metachar:sym<rwb>($/) {
    my $past := PAST::Regex.new( :pasttype('anchor'), :subtype('rwb') );
    make $past;
}

method metachar:sym<bs>($/) {
    make $<backslash>.ast;
}

method metachar:sym<assert>($/) {
    make $<assertion>.ast;
}

method backslash:sym<w>($/) {
    my $subtype := ~$<sym> eq 'n' ?? 'nl' !! ~$<sym>;
    my $past := PAST::Regex.new( :pasttype('charclass'), :subtype($subtype) );
    make $past;
}

method backslash:sym<misc>($/) {
    my $past := PAST::Regex.new( ~$/ , :pasttype('literal') );
    make $past;
}

method assertion:sym<[>($/) {
    make $<cclass_elem>[0].ast;
}

method cclass_elem($/) {
    my $str := '';
    for $<charspec> {
        if $_[1] {
            my $a := $_[0];
            my $b := $_[1][0];
            my $c := Q:PIR {
                         $P0 = find_lex '$a'
                         $S0 = $P0
                         $I0 = ord $S0
                         $P1 = find_lex '$b'
                         $S1 = $P1
                         $I1 = ord $S1
                         $S2 = ''
                       cclass_loop:
                         if $I0 > $I1 goto cclass_done
                         $S0 = chr $I0
                         $S2 .= $S0
                         inc $I0
                         goto cclass_loop
                       cclass_done:
                         %r = box $S2
                     };
            $str := $str ~ $c;            
        }
        else { $str := $str ~ $_[0]; }
    }
    my $past := PAST::Regex.new( $str, :pasttype('enumcharlist') );
    make $past;
}