document.addEventListener('DOMContentLoaded', () => {
	document.querySelectorAll('a.nav-link').forEach(btn => {
		if (!btn.getAttribute('href') || !btn.getAttribute('href').startsWith('#')) return;

		btn.addEventListener('click', e => {
			e.preventDefault();

			const targetId = btn.getAttribute('href').slice(1);
			const target = document.getElementById(targetId);

			if (!target) {
				console.log(`[Collapse] No target found for id: ${targetId}`);
				return;
			}

			console.log(`[Collapse] Clicked toggle for #${targetId}`);

			if (target.classList.contains('show')) {
        // COLLAPSING
				console.log(`[Collapse] Collapsing #${targetId}`);

        // Set current height explicitly
				target.style.height = target.scrollHeight + 'px';

        // Force reflow to apply height before transition
				target.offsetHeight;

        // Transition height to 0
				target.style.transition = 'height 0.3s ease';
				target.style.height = '0px';

				target.addEventListener('transitionend', () => {
					console.log(`[Collapse] Collapse transition ended for #${targetId}`);

          // After collapse finished:
					target.classList.remove('show');

          // Hide from layout flow smoothly now:
          // target.style.display = 'none';

          // Clean inline styles:
					target.style.height = '0px';
					target.style.transition = '';
				}, { once: true });

			} else {
        // EXPANDING
				console.log(`[Collapse] Expanding #${targetId}`);

        // Make element visible immediately (but height 0)
				target.style.display = 'block';

        // Set height 0 explicitly for starting point
				target.style.height = '0px';

        // Force reflow to apply height before transition
				target.offsetHeight;

        // Animate height from 0 to scrollHeight
				const height = target.scrollHeight;
				target.style.transition = 'height 0.3s ease';
				target.style.height = height + 'px';

				target.addEventListener('transitionend', () => {
					console.log(`[Collapse] Expand transition ended for #${targetId}`);

          // Mark as expanded
					target.classList.add('show');

          // Clean inline styles so height is auto again
					target.style.height = '';
					target.style.transition = '';
				}, { once: true });
			}
		});
	});
});
