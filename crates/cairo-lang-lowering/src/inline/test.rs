use std::ops::Deref;

use cairo_lang_debug::DebugWithDb;
use cairo_lang_plugins::get_default_plugins;
use cairo_lang_semantic::db::SemanticGroup;
use cairo_lang_semantic::test_utils::setup_test_function;
use cairo_lang_utils::ordered_hash_map::OrderedHashMap;

use crate::db::LoweringGroup;
use crate::flow::add_fallthroughs;
use crate::fmt::LoweredFormatter;
use crate::inline::apply_inlining;
use crate::test_utils::LoweringDatabaseForTesting;

cairo_lang_test_utils::test_file_test!(
    inlining,
    "src/inline/test_data",
    {

        inline :"inline",
        inline_diagnostics :"inline_diagnostics",
    },
    test_function_inlining
);

fn test_function_inlining(
    inputs: &OrderedHashMap<String, String>,
) -> OrderedHashMap<String, String> {
    let db = &mut LoweringDatabaseForTesting::default();
    db.set_semantic_plugins(get_default_plugins());
    let (test_function, semantic_diagnostics) = setup_test_function(
        db,
        inputs["function"].as_str(),
        inputs["function_name"].as_str(),
        inputs["module_code"].as_str(),
    )
    .split();
    let before = db
        .priv_concrete_function_with_body_lowered_flat(test_function.concrete_function_id)
        .unwrap();

    let lowering_diagnostics = db.module_lowering_diagnostics(test_function.module_id).unwrap();

    let mut after = before.deref().clone();
    apply_inlining(db, test_function.function_id, &mut after).unwrap();

    // TODO(ilya): Move 'add_fallthroughs' to a dedicated test.
    add_fallthroughs(&mut after);

    OrderedHashMap::from([
        ("semantic_diagnostics".into(), semantic_diagnostics),
        (
            "before".into(),
            format!("{:?}", before.debug(&LoweredFormatter { db, variables: &before.variables })),
        ),
        (
            "after".into(),
            format!("{:?}", after.debug(&LoweredFormatter { db, variables: &after.variables })),
        ),
        ("lowering_diagnostics".into(), lowering_diagnostics.format(db)),
    ])
}
