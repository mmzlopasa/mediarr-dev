import numpy as np
from PIL import Image

from app import clip, faces


def test_preprocess_gives_the_shape_and_range_the_model_expects():
    values = clip.preprocess(Image.new("L", (640, 100), color=255))
    assert values.shape == (1, 3, clip.IMAGE_SIZE, clip.IMAGE_SIZE)
    assert values.max() == 1.0
    black = clip.preprocess(Image.new("RGB", (10, 10)))
    assert black.min() == -1.0


def test_text_is_cut_and_padded_to_a_fixed_length():
    assert clip.encode_ids([5, 6]).shape == (1, clip.MAX_TOKENS)
    assert clip.encode_ids([5, 6])[0, 2] == clip.PAD_TOKEN_ID
    assert clip.encode_ids(list(range(1, 200))).shape == (1, clip.MAX_TOKENS)


def test_normalize_has_length_one_and_survives_zero():
    assert abs(np.linalg.norm(clip.normalize(np.array([3.0, 4.0]))) - 1) < 1e-6
    assert clip.normalize(np.zeros(3)) == [0.0, 0.0, 0.0]


def test_letterbox_keeps_the_shape_of_the_picture():
    values, scale = faces.letterbox(Image.new("RGB", (1280, 640), color=(255, 0, 0)))
    assert values.shape == (1, 3, faces.DETECT_SIZE, faces.DETECT_SIZE)
    assert scale == 0.5
    # The model reads blue, green, red: red comes last, and the padding stays black.
    assert values[0, 2, 0, 0] > 0.9
    assert values[0, 0, 0, 0] < -0.9
    assert values[0, 2, 400, 0] < -0.9


def test_anchors_cover_the_picture_twice_per_cell():
    assert len(faces.anchor_centers(8)) == 12800
    assert len(faces.anchor_centers(32)) == 800
    assert faces.anchor_centers(32)[-1].tolist() == [608, 608]


def _outputs(score_at: int, stride_index: int) -> list[np.ndarray]:
    counts = [12800, 3200, 800]
    scores = [np.zeros((count, 1), dtype=np.float32) for count in counts]
    scores[stride_index][score_at] = 0.9
    boxes = [np.ones((count, 4), dtype=np.float32) for count in counts]
    points = [np.zeros((count, 10), dtype=np.float32) for count in counts]
    return scores + boxes + points


def test_decode_places_a_face_where_the_network_says():
    scores, boxes, points = faces.decode(_outputs(0, 2))
    assert scores.tolist() == [np.float32(0.9)]
    # The first cell of the coarsest grid, one stride in every direction.
    assert boxes[0].tolist() == [-32, -32, 32, 32]
    assert points.shape == (1, 5, 2)


def test_decode_finds_nothing_in_nothing():
    outputs = _outputs(0, 0)
    outputs[0][0] = 0
    scores, boxes, points = faces.decode(outputs)
    assert len(scores) == 0 and boxes.shape == (0, 4) and points.shape == (0, 5, 2)


def test_nms_keeps_the_best_of_overlapping_boxes():
    boxes = np.array([[0, 0, 10, 10], [1, 1, 11, 11], [50, 50, 60, 60]], dtype=np.float32)
    assert faces.nms(np.array([0.5, 0.9, 0.7]), boxes) == [1, 2]


def test_alignment_moves_landmarks_onto_the_template():
    matrix = faces.similarity_transform(faces.FACE_TEMPLATE * 2 + 30, faces.FACE_TEMPLATE)
    moved = (matrix[:, :2] @ (faces.FACE_TEMPLATE * 2 + 30).T).T + matrix[:, 2]
    assert np.allclose(moved, faces.FACE_TEMPLATE, atol=1e-6)
