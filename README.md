# kubeflow-mnist

## Running Locally

Install the Conda environment:

```sh
conda env create -f environment.yml
```

Then run training:

```sh
% python preprocessing.py --data_dir data
% python train.py --data_dir data --model_path export
```

## Building the image

DOCKER_BUILDKIT=1 docker build -t dcavanau/kubeflow-mnist env -f Dockerfile

## Tensorflow Serving

docker run -t --rm -p 8501:8501 \
    -v "$PWD/export:/models/mnist" \
    -e MODEL_NAME=mnist \
    tensorflow/serving:2.4.2
