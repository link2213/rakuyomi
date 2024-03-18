use cli::{chapter_downloader::download_chapter_pages_as_cbz, source::Source};
use criterion::{black_box, criterion_group, criterion_main, Criterion};
use pprof::criterion::{Output, PProfProfiler};
use std::{env, io, path::PathBuf};

pub fn chapter_downloader_benchmark(c: &mut Criterion) {
    let source_path: PathBuf = env::var("BENCHMARK_SOURCE_PATH").unwrap().into();
    let manga_id = env::var("BENCHMARK_MANGA_ID").unwrap();
    let chapter_id = env::var("BENCHMARK_CHAPTER_ID").unwrap();

    let mut source = Source::from_aix_file(source_path.as_ref()).unwrap();
    let pages = source.get_page_list(manga_id, chapter_id).unwrap();

    let runtime = tokio::runtime::Runtime::new().unwrap();

    c.bench_function("download_chapter_pages_as_cbz", |b| {
        b.to_async(&runtime)
            .iter(|| download_chapter_pages_as_cbz(io::Cursor::new(Vec::new()), pages.clone()))
    });
}

criterion_group! {
    name = benches;
    config = Criterion::default().sample_size(10).with_profiler(PProfProfiler::new(100, Output::Flamegraph(None)));
    targets = chapter_downloader_benchmark
}
criterion_main!(benches);