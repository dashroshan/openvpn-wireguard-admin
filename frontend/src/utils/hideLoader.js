export default function hideLoader() {
    const onPageLoad = () => {
        setTimeout(() => {
            document.getElementById("loader_block").style.opacity = 0;
            setTimeout(() => {
                document.getElementById("loader_block").style.display = "none";
            }, 310);
        }, 200);
    };
    if (document.readyState === 'complete') {
        onPageLoad();
    } else {
        window.addEventListener('load', onPageLoad, false);
        return () => window.removeEventListener('load', onPageLoad);
    }
}