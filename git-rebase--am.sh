#!/bin/sh
#
# Copyright (c) 2010 Junio C Hamano.
#

case "$action" in
continue)
	git am --resolved --resolvemsg="$resolvemsg" &&
	move_to_original_branch
	return
	;;
skip)
	git am --skip --resolvemsg="$resolvemsg" &&
	move_to_original_branch
	return
	;;
esac

test -n "$rebase_root" && root_flag=--root

ret=0

	rm -f "$GIT_DIR/rebased-patches"

	git format-patch -k --stdout --full-index --ignore-if-in-upstream \
		--src-prefix=a/ --dst-prefix=b/ --no-renames --no-cover-letter \
		$root_flag "$revisions" >"$GIT_DIR/rebased-patches"
	ret=$?

	if test 0 != $ret
	then
		rm -f "$GIT_DIR/rebased-patches"
		case "$head_name" in
		refs/heads/*)
			git checkout -q "$head_name"
			;;
		*)
			git checkout -q "$orig_head"
			;;
		esac

		cat >&2 <<-EOF

		git encountered an error while preparing the patches to replay
		these revisions:

		    $revisions

		As a result, git cannot rebase them.
		EOF
		return $?
	fi

	test -n "$GIT_QUIET" && git_am_opt="$git_am_opt -q"
	git am $git_am_opt --rebasing --resolvemsg="$resolvemsg" <"$GIT_DIR/rebased-patches"
	ret=$?

	rm -f "$GIT_DIR/rebased-patches"

if test 0 != $ret
then
	test -d "$state_dir" && write_basic_state
	return $ret
fi

move_to_original_branch
